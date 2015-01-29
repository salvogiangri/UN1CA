# Copyright (C) 2015 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from __future__ import print_function
from collections import deque, OrderedDict
from hashlib import sha1
import itertools
import multiprocessing
import os
import pprint
import re
import subprocess
import sys
import threading
import tempfile
from rangelib import *
__all__ = ["EmptyImage", "DataImage", "BlockImageDiff"]
def compute_patch(src, tgt, imgdiff=False):
  srcfd, srcfile = tempfile.mkstemp(prefix="src-")
  tgtfd, tgtfile = tempfile.mkstemp(prefix="tgt-")
  patchfd, patchfile = tempfile.mkstemp(prefix="patch-")
  os.close(patchfd)
  try:
    with os.fdopen(srcfd, "wb") as f_src:
      for p in src:
        f_src.write(p)
    with os.fdopen(tgtfd, "wb") as f_tgt:
      for p in tgt:
        f_tgt.write(p)
    try:
      os.unlink(patchfile)
    except OSError:
      pass
    if imgdiff:
      p = subprocess.call(["imgdiff", "-z", srcfile, tgtfile, patchfile],
                          stdout=open("/dev/null", "a"),
                          stderr=subprocess.STDOUT)
    else:
      p = subprocess.call(["bsdiff", srcfile, tgtfile, patchfile])
    if p:
      raise ValueError("diff failed: " + str(p))
    with open(patchfile, "rb") as f:
      return f.read()
  finally:
    try:
      os.unlink(srcfile)
      os.unlink(tgtfile)
      os.unlink(patchfile)
    except OSError:
      pass
class EmptyImage(object):
  """A zero-length image."""
  blocksize = 4096
  care_map = RangeSet()
  total_blocks = 0
  file_map = {}
  def ReadRangeSet(self, ranges):
    return ()
  def TotalSha1(self):
    return sha1().hexdigest()
class DataImage(object):
  """An image wrapped around a single string of data."""
  def __init__(self, data, trim=False, pad=False):
    self.data = data
    self.blocksize = 4096
    assert not (trim and pad)
    partial = len(self.data) % self.blocksize
    if partial > 0:
      if trim:
        self.data = self.data[:-partial]
      elif pad:
        self.data += '\0' * (self.blocksize - partial)
      else:
        raise ValueError(("data for DataImage must be multiple of %d bytes "
                          "unless trim or pad is specified") %
                         (self.blocksize,))
    assert len(self.data) % self.blocksize == 0
    self.total_blocks = len(self.data) / self.blocksize
    self.care_map = RangeSet(data=(0, self.total_blocks))
    zero_blocks = []
    nonzero_blocks = []
    reference = '\0' * self.blocksize
    for i in range(self.total_blocks):
      d = self.data[i*self.blocksize : (i+1)*self.blocksize]
      if d == reference:
        zero_blocks.append(i)
        zero_blocks.append(i+1)
      else:
        nonzero_blocks.append(i)
        nonzero_blocks.append(i+1)
    self.file_map = {"__ZERO": RangeSet(zero_blocks),
                     "__NONZERO": RangeSet(nonzero_blocks)}
  def ReadRangeSet(self, ranges):
    return [self.data[s*self.blocksize:e*self.blocksize] for (s, e) in ranges]
  def TotalSha1(self):
    if not hasattr(self, "sha1"):
      self.sha1 = sha1(self.data).hexdigest()
    return self.sha1
class Transfer(object):
  def __init__(self, tgt_name, src_name, tgt_ranges, src_ranges, style, by_id):
    self.tgt_name = tgt_name
    self.src_name = src_name
    self.tgt_ranges = tgt_ranges
    self.src_ranges = src_ranges
    self.style = style
    self.intact = (getattr(tgt_ranges, "monotonic", False) and
                   getattr(src_ranges, "monotonic", False))
    self.goes_before = {}
    self.goes_after = {}
    self.id = len(by_id)
    by_id.append(self)
  def __str__(self):
    return (str(self.id) + ": <" + str(self.src_ranges) + " " + self.style +
            " to " + str(self.tgt_ranges) + ">")
# BlockImageDiff works on two image objects.  An image object is
# anything that provides the following attributes:
#
#    blocksize: the size in bytes of a block, currently must be 4096.
#
#    total_blocks: the total size of the partition/image, in blocks.
#
#    care_map: a RangeSet containing which blocks (in the range [0,
#      total_blocks) we actually care about; i.e. which blocks contain
#      data.
#
#    file_map: a dict that partitions the blocks contained in care_map
#      into smaller domains that are useful for doing diffs on.
#      (Typically a domain is a file, and the key in file_map is the
#      pathname.)
#
#    ReadRangeSet(): a function that takes a RangeSet and returns the
#      data contained in the image blocks of that RangeSet.  The data
#      is returned as a list or tuple of strings; concatenating the
#      elements together should produce the requested data.
#      Implementations are free to break up the data into list/tuple
#      elements in any way that is convenient.
#
#    TotalSha1(): a function that returns (as a hex string) the SHA-1
#      hash of all the data in the image (ie, all the blocks in the
#      care_map)
#
# When creating a BlockImageDiff, the src image may be None, in which
# case the list of transfers produced will never read from the
# original image.
class BlockImageDiff(object):
  def __init__(self, tgt, src=None, threads=None):
    if threads is None:
      threads = multiprocessing.cpu_count() // 2
      if threads == 0: threads = 1
    self.threads = threads
    self.tgt = tgt
    if src is None:
      src = EmptyImage()
    self.src = src
    # The updater code that installs the patch always uses 4k blocks.
    assert tgt.blocksize == 4096
    assert src.blocksize == 4096
    # The range sets in each filemap should comprise a partition of
    # the care map.
    self.AssertPartition(src.care_map, src.file_map.values())
    self.AssertPartition(tgt.care_map, tgt.file_map.values())
  def Compute(self, prefix):
    # When looking for a source file to use as the diff input for a
    # target file, we try:
    #   1) an exact path match if available, otherwise
    #   2) a exact basename match if available, otherwise
    #   3) a basename match after all runs of digits are replaced by
    #      "#" if available, otherwise
    #   4) we have no source for this target.
    self.AbbreviateSourceNames()
    self.FindTransfers()
    # Find the ordering dependencies among transfers (this is O(n^2)
    # in the number of transfers).
    self.GenerateDigraph()
    # Find a sequence of transfers that satisfies as many ordering
    # dependencies as possible (heuristically).
    self.FindVertexSequence()
    # Fix up the ordering dependencies that the sequence didn't
    # satisfy.
    self.RemoveBackwardEdges()
    # Double-check our work.
    self.AssertSequenceGood()
    self.ComputePatches(prefix)
    self.WriteTransfers(prefix)
  def WriteTransfers(self, prefix):
    out = []
    out.append("1\n")   # format version number
    total = 0
    performs_read = False
    for xf in self.transfers:
      # zero [rangeset]
      # new [rangeset]
      # bsdiff patchstart patchlen [src rangeset] [tgt rangeset]
      # imgdiff patchstart patchlen [src rangeset] [tgt rangeset]
      # move [src rangeset] [tgt rangeset]
      # erase [rangeset]
      tgt_size = xf.tgt_ranges.size()
      if xf.style == "new":
        assert xf.tgt_ranges
        out.append("%s %s\n" % (xf.style, xf.tgt_ranges.to_string_raw()))
        total += tgt_size
      elif xf.style == "move":
        performs_read = True
        assert xf.tgt_ranges
        assert xf.src_ranges.size() == tgt_size
        if xf.src_ranges != xf.tgt_ranges:
          out.append("%s %s %s\n" % (
              xf.style,
              xf.src_ranges.to_string_raw(), xf.tgt_ranges.to_string_raw()))
          total += tgt_size
      elif xf.style in ("bsdiff", "imgdiff"):
        performs_read = True
        assert xf.tgt_ranges
        assert xf.src_ranges
        out.append("%s %d %d %s %s\n" % (
            xf.style, xf.patch_start, xf.patch_len,
            xf.src_ranges.to_string_raw(), xf.tgt_ranges.to_string_raw()))
        total += tgt_size
      elif xf.style == "zero":
        assert xf.tgt_ranges
        to_zero = xf.tgt_ranges.subtract(xf.src_ranges)
        if to_zero:
          out.append("%s %s\n" % (xf.style, to_zero.to_string_raw()))
          total += to_zero.size()
      else:
        raise ValueError("unknown transfer style '%s'\n" % (xf.style,))
    out.insert(1, str(total) + "\n")
    all_tgt = RangeSet(data=(0, self.tgt.total_blocks))
    if performs_read:
      # if some of the original data is used, then at the end we'll
      # erase all the blocks on the partition that don't contain data
      # in the new image.
      new_dontcare = all_tgt.subtract(self.tgt.care_map)
      if new_dontcare:
        out.append("erase %s\n" % (new_dontcare.to_string_raw(),))
    else:
      # if nothing is read (ie, this is a full OTA), then we can start
      # by erasing the entire partition.
      out.insert(2, "erase %s\n" % (all_tgt.to_string_raw(),))
    with open(prefix + ".transfer.list", "wb") as f:
      for i in out:
        f.write(i)
  def ComputePatches(self, prefix):
    print("Reticulating splines...")
    diff_q = []
    patch_num = 0
    with open(prefix + ".new.dat", "wb") as new_f:
      for xf in self.transfers:
        if xf.style == "zero":
          pass
        elif xf.style == "new":
          for piece in self.tgt.ReadRangeSet(xf.tgt_ranges):
            new_f.write(piece)
        elif xf.style == "diff":
          src = self.src.ReadRangeSet(xf.src_ranges)
          tgt = self.tgt.ReadRangeSet(xf.tgt_ranges)
          # We can't compare src and tgt directly because they may have
          # the same content but be broken up into blocks differently, eg:
          #
          #    ["he", "llo"]  vs  ["h", "ello"]
          #
          # We want those to compare equal, ideally without having to
          # actually concatenate the strings (these may be tens of
          # megabytes).
          src_sha1 = sha1()
          for p in src:
            src_sha1.update(p)
          tgt_sha1 = sha1()
          tgt_size = 0
          for p in tgt:
            tgt_sha1.update(p)
            tgt_size += len(p)
          if src_sha1.digest() == tgt_sha1.digest():
            # These are identical; we don't need to generate a patch,
            # just issue copy commands on the device.
            xf.style = "move"
          else:
            # For files in zip format (eg, APKs, JARs, etc.) we would
            # like to use imgdiff -z if possible (because it usually
            # produces significantly smaller patches than bsdiff).
            # This is permissible if:
            #
            #  - the source and target files are monotonic (ie, the
            #    data is stored with blocks in increasing order), and
            #  - we haven't removed any blocks from the source set.
            #
            # If these conditions are satisfied then appending all the
            # blocks in the set together in order will produce a valid
            # zip file (plus possibly extra zeros in the last block),
            # which is what imgdiff needs to operate.  (imgdiff is
            # fine with extra zeros at the end of the file.)
            imgdiff = (xf.intact and
                       xf.tgt_name.split(".")[-1].lower()
                       in ("apk", "jar", "zip"))
            xf.style = "imgdiff" if imgdiff else "bsdiff"
            diff_q.append((tgt_size, src, tgt, xf, patch_num))
            patch_num += 1
        else:
          assert False, "unknown style " + xf.style
    if diff_q:
      if self.threads > 1:
        print("Computing patches (using %d threads)..." % (self.threads,))
      else:
        print("Computing patches...")
      diff_q.sort()
      patches = [None] * patch_num
      lock = threading.Lock()
      def diff_worker():
        while True:
          with lock:
            if not diff_q: return
            tgt_size, src, tgt, xf, patchnum = diff_q.pop()
          patch = compute_patch(src, tgt, imgdiff=(xf.style == "imgdiff"))
          size = len(patch)
          with lock:
            patches[patchnum] = (patch, xf)
            print("%10d %10d (%6.2f%%) %7s %s" % (
                size, tgt_size, size * 100.0 / tgt_size, xf.style,
                xf.tgt_name if xf.tgt_name == xf.src_name else (
                    xf.tgt_name + " (from " + xf.src_name + ")")))
      threads = [threading.Thread(target=diff_worker)
                 for i in range(self.threads)]
      for th in threads:
        th.start()
      while threads:
        threads.pop().join()
    else:
      patches = []
    p = 0
    with open(prefix + ".patch.dat", "wb") as patch_f:
      for patch, xf in patches:
        xf.patch_start = p
        xf.patch_len = len(patch)
        patch_f.write(patch)
        p += len(patch)
  def AssertSequenceGood(self):
    # Simulate the sequences of transfers we will output, and check that:
    # - we never read a block after writing it, and
    # - we write every block we care about exactly once.
    # Start with no blocks having been touched yet.
    touched = RangeSet()
    # Imagine processing the transfers in order.
    for xf in self.transfers:
      # Check that the input blocks for this transfer haven't yet been touched.
      assert not touched.overlaps(xf.src_ranges)
      # Check that the output blocks for this transfer haven't yet been touched.
      assert not touched.overlaps(xf.tgt_ranges)
      # Touch all the blocks written by this transfer.
      touched = touched.union(xf.tgt_ranges)
    # Check that we've written every target block.
    assert touched == self.tgt.care_map
  def RemoveBackwardEdges(self):
    print("Removing backward edges...")
    in_order = 0
    out_of_order = 0
    lost_source = 0
    for xf in self.transfers:
      io = 0
      ooo = 0
      lost = 0
      size = xf.src_ranges.size()
      for u in xf.goes_before:
        # xf should go before u
        if xf.order < u.order:
          # it does, hurray!
          io += 1
        else:
          # it doesn't, boo.  trim the blocks that u writes from xf's
          # source, so that xf can go after u.
          ooo += 1
          assert xf.src_ranges.overlaps(u.tgt_ranges)
          xf.src_ranges = xf.src_ranges.subtract(u.tgt_ranges)
          xf.intact = False
      if xf.style == "diff" and not xf.src_ranges:
        # nothing left to diff from; treat as new data
        xf.style = "new"
      lost = size - xf.src_ranges.size()
      lost_source += lost
      in_order += io
      out_of_order += ooo
    print(("  %d/%d dependencies (%.2f%%) were violated; "
           "%d source blocks removed.") %
          (out_of_order, in_order + out_of_order,
           (out_of_order * 100.0 / (in_order + out_of_order))
           if (in_order + out_of_order) else 0.0,
           lost_source))
  def FindVertexSequence(self):
    print("Finding vertex sequence...")
    # This is based on "A Fast & Effective Heuristic for the Feedback
    # Arc Set Problem" by P. Eades, X. Lin, and W.F. Smyth.  Think of
    # it as starting with the digraph G and moving all the vertices to
    # be on a horizontal line in some order, trying to minimize the
    # number of edges that end up pointing to the left.  Left-pointing
    # edges will get removed to turn the digraph into a DAG.  In this
    # case each edge has a weight which is the number of source blocks
    # we'll lose if that edge is removed; we try to minimize the total
    # weight rather than just the number of edges.
    # Make a copy of the edge set; this copy will get destroyed by the
    # algorithm.
    for xf in self.transfers:
      xf.incoming = xf.goes_after.copy()
      xf.outgoing = xf.goes_before.copy()
    # We use an OrderedDict instead of just a set so that the output
    # is repeatable; otherwise it would depend on the hash values of
    # the transfer objects.
    G = OrderedDict()
    for xf in self.transfers:
      G[xf] = None
    s1 = deque()  # the left side of the sequence, built from left to right
    s2 = deque()  # the right side of the sequence, built from right to left
    while G:
      # Put all sinks at the end of the sequence.
      while True:
        sinks = [u for u in G if not u.outgoing]
        if not sinks: break
        for u in sinks:
          s2.appendleft(u)
          del G[u]
          for iu in u.incoming:
            del iu.outgoing[u]
      # Put all the sources at the beginning of the sequence.
      while True:
        sources = [u for u in G if not u.incoming]
        if not sources: break
        for u in sources:
          s1.append(u)
          del G[u]
          for iu in u.outgoing:
            del iu.incoming[u]
      if not G: break
      # Find the "best" vertex to put next.  "Best" is the one that
      # maximizes the net difference in source blocks saved we get by
      # pretending it's a source rather than a sink.
      max_d = None
      best_u = None
      for u in G:
        d = sum(u.outgoing.values()) - sum(u.incoming.values())
        if best_u is None or d > max_d:
          max_d = d
          best_u = u
      u = best_u
      s1.append(u)
      del G[u]
      for iu in u.outgoing:
        del iu.incoming[u]
      for iu in u.incoming:
        del iu.outgoing[u]
    # Now record the sequence in the 'order' field of each transfer,
    # and by rearranging self.transfers to be in the chosen sequence.
    new_transfers = []
    for x in itertools.chain(s1, s2):
      x.order = len(new_transfers)
      new_transfers.append(x)
      del x.incoming
      del x.outgoing
    self.transfers = new_transfers
  def GenerateDigraph(self):
    print("Generating digraph...")
    for a in self.transfers:
      for b in self.transfers:
        if a is b: continue
        # If the blocks written by A are read by B, then B needs to go before A.
        i = a.tgt_ranges.intersect(b.src_ranges)
        if i:
          if b.src_name == "__ZERO":
            # the cost of removing source blocks for the __ZERO domain
            # is (nearly) zero.
            size = 0
          else:
            size = i.size()
          b.goes_before[a] = size
          a.goes_after[b] = size
  def FindTransfers(self):
    self.transfers = []
    empty = RangeSet()
    for tgt_fn, tgt_ranges in self.tgt.file_map.items():
      if tgt_fn == "__ZERO":
        # the special "__ZERO" domain is all the blocks not contained
        # in any file and that are filled with zeros.  We have a
        # special transfer style for zero blocks.
        src_ranges = self.src.file_map.get("__ZERO", empty)
        Transfer(tgt_fn, "__ZERO", tgt_ranges, src_ranges,
                 "zero", self.transfers)
        continue
      elif tgt_fn in self.src.file_map:
        # Look for an exact pathname match in the source.
        Transfer(tgt_fn, tgt_fn, tgt_ranges, self.src.file_map[tgt_fn],
                 "diff", self.transfers)
        continue
      b = os.path.basename(tgt_fn)
      if b in self.src_basenames:
        # Look for an exact basename match in the source.
        src_fn = self.src_basenames[b]
        Transfer(tgt_fn, src_fn, tgt_ranges, self.src.file_map[src_fn],
                 "diff", self.transfers)
        continue
      b = re.sub("[0-9]+", "#", b)
      if b in self.src_numpatterns:
        # Look for a 'number pattern' match (a basename match after
        # all runs of digits are replaced by "#").  (This is useful
        # for .so files that contain version numbers in the filename
        # that get bumped.)
        src_fn = self.src_numpatterns[b]
        Transfer(tgt_fn, src_fn, tgt_ranges, self.src.file_map[src_fn],
                 "diff", self.transfers)
        continue
      Transfer(tgt_fn, None, tgt_ranges, empty, "new", self.transfers)
  def AbbreviateSourceNames(self):
    self.src_basenames = {}
    self.src_numpatterns = {}
    for k in self.src.file_map.keys():
      b = os.path.basename(k)
      self.src_basenames[b] = k
      b = re.sub("[0-9]+", "#", b)
      self.src_numpatterns[b] = k
  @staticmethod
  def AssertPartition(total, seq):
    """Assert that all the RangeSets in 'seq' form a partition of the
    'total' RangeSet (ie, they are nonintersecting and their union
    equals 'total')."""
    so_far = RangeSet()
    for i in seq:
      assert not so_far.overlaps(i)
      so_far = so_far.union(i)
    assert so_far == total
