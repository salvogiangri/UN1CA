# Copyright (C) 2014 The Android Open Source Project
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
import array
import common
import functools
import heapq
import itertools
import multiprocessing
import os
import re
import subprocess
import threading
import time
import tempfile

from rangelib import RangeSet


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


class Image(object):
  def ReadRangeSet(self, ranges):
    raise NotImplementedError

  def TotalSha1(self, include_clobbered_blocks=False):
    raise NotImplementedError


class EmptyImage(Image):
  """A zero-length image."""
  blocksize = 4096
  care_map = RangeSet()
  clobbered_blocks = RangeSet()
  extended = RangeSet()
  total_blocks = 0
  file_map = {}
  def ReadRangeSet(self, ranges):
    return ()
  def TotalSha1(self, include_clobbered_blocks=False):
    # EmptyImage always carries empty clobbered_blocks, so
    # include_clobbered_blocks can be ignored.
    assert self.clobbered_blocks.size() == 0
    return sha1().hexdigest()


class DataImage(Image):
  """An image wrapped around a single string of data."""

  def __init__(self, data, trim=False, pad=False):
    self.data = data
    self.blocksize = 4096

    assert not (trim and pad)

    partial = len(self.data) % self.blocksize
    padded = False
    if partial > 0:
      if trim:
        self.data = self.data[:-partial]
      elif pad:
        self.data += '\0' * (self.blocksize - partial)
        padded = True
      else:
        raise ValueError(("data for DataImage must be multiple of %d bytes "
                          "unless trim or pad is specified") %
                         (self.blocksize,))

    assert len(self.data) % self.blocksize == 0

    self.total_blocks = len(self.data) / self.blocksize
    self.care_map = RangeSet(data=(0, self.total_blocks))
    # When the last block is padded, we always write the whole block even for
    # incremental OTAs. Because otherwise the last block may get skipped if
    # unchanged for an incremental, but would fail the post-install
    # verification if it has non-zero contents in the padding bytes.
    # Bug: 23828506
    if padded:
      clobbered_blocks = [self.total_blocks-1, self.total_blocks]
    else:
      clobbered_blocks = []
    self.clobbered_blocks = clobbered_blocks
    self.extended = RangeSet()

    zero_blocks = []
    nonzero_blocks = []
    reference = '\0' * self.blocksize

    for i in range(self.total_blocks-1 if padded else self.total_blocks):
      d = self.data[i*self.blocksize : (i+1)*self.blocksize]
      if d == reference:
        zero_blocks.append(i)
        zero_blocks.append(i+1)
      else:
        nonzero_blocks.append(i)
        nonzero_blocks.append(i+1)

    assert zero_blocks or nonzero_blocks or clobbered_blocks

    self.file_map = dict()
    if zero_blocks:
      self.file_map["__ZERO"] = RangeSet(data=zero_blocks)
    if nonzero_blocks:
      self.file_map["__NONZERO"] = RangeSet(data=nonzero_blocks)
    if clobbered_blocks:
      self.file_map["__COPY"] = RangeSet(data=clobbered_blocks)

  def ReadRangeSet(self, ranges):
    return [self.data[s*self.blocksize:e*self.blocksize] for (s, e) in ranges]

  def TotalSha1(self, include_clobbered_blocks=False):
    if not include_clobbered_blocks:
      ranges = self.care_map.subtract(self.clobbered_blocks)
      return sha1(self.ReadRangeSet(ranges)).hexdigest()
    else:
      return sha1(self.data).hexdigest()


class Transfer(object):
  def __init__(self, tgt_name, src_name, tgt_ranges, src_ranges, style, by_id):
    self.tgt_name = tgt_name
    self.src_name = src_name
    self.tgt_ranges = tgt_ranges
    self.src_ranges = src_ranges
    self.style = style
    self.intact = (getattr(tgt_ranges, "monotonic", False) and
                   getattr(src_ranges, "monotonic", False))

    # We use OrderedDict rather than dict so that the output is repeatable;
    # otherwise it would depend on the hash values of the Transfer objects.
    self.goes_before = OrderedDict()
    self.goes_after = OrderedDict()

    self.stash_before = []
    self.use_stash = []

    self.id = len(by_id)
    by_id.append(self)

  def NetStashChange(self):
    return (sum(sr.size() for (_, sr) in self.stash_before) -
            sum(sr.size() for (_, sr) in self.use_stash))

  def ConvertToNew(self):
    assert self.style != "new"
    self.use_stash = []
    self.style = "new"
    self.src_ranges = RangeSet()

  def __str__(self):
    return (str(self.id) + ": <" + str(self.src_ranges) + " " + self.style +
            " to " + str(self.tgt_ranges) + ">")


@functools.total_ordering
class HeapItem(object):
  def __init__(self, item):
    self.item = item
    # Negate the score since python's heap is a min-heap and we want
    # the maximum score.
    self.score = -item.score
  def clear(self):
    self.item = None
  def __bool__(self):
    return self.item is None
  def __eq__(self, other):
    return self.score == other.score
  def __le__(self, other):
    return self.score <= other.score


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
#    clobbered_blocks: a RangeSet containing which blocks contain data
#      but may be altered by the FS. They need to be excluded when
#      verifying the partition integrity.
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
#      care_map minus clobbered_blocks, or including the clobbered
#      blocks if include_clobbered_blocks is True).
#
# When creating a BlockImageDiff, the src image may be None, in which
# case the list of transfers produced will never read from the
# original image.

class BlockImageDiff(object):
  def __init__(self, tgt, src=None, version=4, threads=None,
               disable_imgdiff=False):
    if threads is None:
      threads = multiprocessing.cpu_count() // 2
      if threads == 0:
        threads = 1
    self.threads = threads
    self.version = version
    self.transfers = []
    self.src_basenames = {}
    self.src_numpatterns = {}
    self._max_stashed_size = 0
    self.touched_src_ranges = RangeSet()
    self.touched_src_sha1 = None
    self.disable_imgdiff = disable_imgdiff

    assert version in (1, 2, 3, 4)

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

  @property
  def max_stashed_size(self):
    return self._max_stashed_size

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
    if self.version == 1:
      self.RemoveBackwardEdges()
    else:
      self.ReverseBackwardEdges()
      self.ImproveVertexSequence()

    # Ensure the runtime stash size is under the limit.
    if self.version >= 2 and common.OPTIONS.cache_size is not None:
      self.ReviseStashSize()

    # Double-check our work.
    self.AssertSequenceGood()

    self.ComputePatches(prefix)
    self.WriteTransfers(prefix)

  def HashBlocks(self, source, ranges): # pylint: disable=no-self-use
    data = source.ReadRangeSet(ranges)
    ctx = sha1()

    for p in data:
      ctx.update(p)

    return ctx.hexdigest()

  def WriteTransfers(self, prefix):
    def WriteTransfersZero(out, to_zero):
      """Limit the number of blocks in command zero to 1024 blocks.

      This prevents the target size of one command from being too large; and
      might help to avoid fsync errors on some devices."""

      zero_blocks_limit = 1024
      total = 0
      while to_zero.size() > 0:
        zero_blocks = to_zero.first(zero_blocks_limit)
        out.append("zero %s\n" % (zero_blocks.to_string_raw(),))
        total += zero_blocks.size()
        to_zero = to_zero.subtract(zero_blocks)
      return total

    out = []

    total = 0

    stashes = {}
    stashed_blocks = 0
    max_stashed_blocks = 0

    free_stash_ids = []
    next_stash_id = 0

    for xf in self.transfers:

      if self.version < 2:
        assert not xf.stash_before
        assert not xf.use_stash

      for s, sr in xf.stash_before:
        assert s not in stashes
        if free_stash_ids:
          sid = heapq.heappop(free_stash_ids)
        else:
          sid = next_stash_id
          next_stash_id += 1
        stashes[s] = sid
        if self.version == 2:
          stashed_blocks += sr.size()
          out.append("stash %d %s\n" % (sid, sr.to_string_raw()))
        else:
          sh = self.HashBlocks(self.src, sr)
          if sh in stashes:
            stashes[sh] += 1
          else:
            stashes[sh] = 1
            stashed_blocks += sr.size()
            self.touched_src_ranges = self.touched_src_ranges.union(sr)
            out.append("stash %s %s\n" % (sh, sr.to_string_raw()))

      if stashed_blocks > max_stashed_blocks:
        max_stashed_blocks = stashed_blocks

      free_string = []
      free_size = 0

      if self.version == 1:
        src_str = xf.src_ranges.to_string_raw() if xf.src_ranges.size() > 0 else ""
      elif self.version >= 2:

        #   <# blocks> <src ranges>
        #     OR
        #   <# blocks> <src ranges> <src locs> <stash refs...>
        #     OR
        #   <# blocks> - <stash refs...>

        size = xf.src_ranges.size()
        src_str = [str(size)]

        unstashed_src_ranges = xf.src_ranges
        mapped_stashes = []
        for s, sr in xf.use_stash:
          sid = stashes.pop(s)
          unstashed_src_ranges = unstashed_src_ranges.subtract(sr)
          sh = self.HashBlocks(self.src, sr)
          sr = xf.src_ranges.map_within(sr)
          mapped_stashes.append(sr)
          if self.version == 2:
            src_str.append("%d:%s" % (sid, sr.to_string_raw()))
            # A stash will be used only once. We need to free the stash
            # immediately after the use, instead of waiting for the automatic
            # clean-up at the end. Because otherwise it may take up extra space
            # and lead to OTA failures.
            # Bug: 23119955
            free_string.append("free %d\n" % (sid,))
            free_size += sr.size()
          else:
            assert sh in stashes
            src_str.append("%s:%s" % (sh, sr.to_string_raw()))
            stashes[sh] -= 1
            if stashes[sh] == 0:
              free_size += sr.size()
              free_string.append("free %s\n" % (sh))
              stashes.pop(sh)
          heapq.heappush(free_stash_ids, sid)

        if unstashed_src_ranges.size() > 0:
          src_str.insert(1, unstashed_src_ranges.to_string_raw())
          if xf.use_stash:
            mapped_unstashed = xf.src_ranges.map_within(unstashed_src_ranges)
            src_str.insert(2, mapped_unstashed.to_string_raw())
            mapped_stashes.append(mapped_unstashed)
            self.AssertPartition(RangeSet(data=(0, size)), mapped_stashes)
        else:
          src_str.insert(1, "-")
          self.AssertPartition(RangeSet(data=(0, size)), mapped_stashes)

        src_str = " ".join(src_str)

      # all versions:
      #   zero <rangeset>
      #   new <rangeset>
      #   erase <rangeset>
      #
      # version 1:
      #   bsdiff patchstart patchlen <src rangeset> <tgt rangeset>
      #   imgdiff patchstart patchlen <src rangeset> <tgt rangeset>
      #   move <src rangeset> <tgt rangeset>
      #
      # version 2:
      #   bsdiff patchstart patchlen <tgt rangeset> <src_str>
      #   imgdiff patchstart patchlen <tgt rangeset> <src_str>
      #   move <tgt rangeset> <src_str>
      #
      # version 3:
      #   bsdiff patchstart patchlen srchash tgthash <tgt rangeset> <src_str>
      #   imgdiff patchstart patchlen srchash tgthash <tgt rangeset> <src_str>
      #   move hash <tgt rangeset> <src_str>

      tgt_size = xf.tgt_ranges.size()

      if xf.style == "new":
        assert xf.tgt_ranges
        out.append("%s %s\n" % (xf.style, xf.tgt_ranges.to_string_raw()))
        total += tgt_size
      elif xf.style == "move":
        assert xf.tgt_ranges
        assert xf.src_ranges.size() == tgt_size
        if xf.src_ranges != xf.tgt_ranges:
          if self.version == 1:
            out.append("%s %s %s\n" % (
                xf.style,
                xf.src_ranges.to_string_raw(), xf.tgt_ranges.to_string_raw()))
          elif self.version == 2:
            out.append("%s %s %s\n" % (
                xf.style,
                xf.tgt_ranges.to_string_raw(), src_str))
          elif self.version >= 3:
            # take into account automatic stashing of overlapping blocks
            if xf.src_ranges.overlaps(xf.tgt_ranges):
              temp_stash_usage = stashed_blocks + xf.src_ranges.size()
              if temp_stash_usage > max_stashed_blocks:
                max_stashed_blocks = temp_stash_usage

            self.touched_src_ranges = self.touched_src_ranges.union(
                xf.src_ranges)

            out.append("%s %s %s %s\n" % (
                xf.style,
                self.HashBlocks(self.tgt, xf.tgt_ranges),
                xf.tgt_ranges.to_string_raw(), src_str))
          total += tgt_size
      elif xf.style in ("bsdiff", "imgdiff"):
        assert xf.tgt_ranges
        assert xf.src_ranges
        if self.version == 1:
          out.append("%s %d %d %s %s\n" % (
              xf.style, xf.patch_start, xf.patch_len,
              xf.src_ranges.to_string_raw(), xf.tgt_ranges.to_string_raw()))
        elif self.version == 2:
          out.append("%s %d %d %s %s\n" % (
              xf.style, xf.patch_start, xf.patch_len,
              xf.tgt_ranges.to_string_raw(), src_str))
        elif self.version >= 3:
          # take into account automatic stashing of overlapping blocks
          if xf.src_ranges.overlaps(xf.tgt_ranges):
            temp_stash_usage = stashed_blocks + xf.src_ranges.size()
            if temp_stash_usage > max_stashed_blocks:
              max_stashed_blocks = temp_stash_usage

          self.touched_src_ranges = self.touched_src_ranges.union(
              xf.src_ranges)

          out.append("%s %d %d %s %s %s %s\n" % (
              xf.style,
              xf.patch_start, xf.patch_len,
              self.HashBlocks(self.src, xf.src_ranges),
              self.HashBlocks(self.tgt, xf.tgt_ranges),
              xf.tgt_ranges.to_string_raw(), src_str))
        total += tgt_size
      elif xf.style == "zero":
        assert xf.tgt_ranges
        to_zero = xf.tgt_ranges.subtract(xf.src_ranges)
        assert WriteTransfersZero(out, to_zero) == to_zero.size()
        total += to_zero.size()
      else:
        raise ValueError("unknown transfer style '%s'\n" % xf.style)

      if free_string:
        out.append("".join(free_string))
        stashed_blocks -= free_size

      if self.version >= 2 and common.OPTIONS.cache_size is not None:
        # Sanity check: abort if we're going to need more stash space than
        # the allowed size (cache_size * threshold). There are two purposes
        # of having a threshold here. a) Part of the cache may have been
        # occupied by some recovery logs. b) It will buy us some time to deal
        # with the oversize issue.
        cache_size = common.OPTIONS.cache_size
        stash_threshold = common.OPTIONS.stash_threshold
        max_allowed = cache_size * stash_threshold
        assert max_stashed_blocks * self.tgt.blocksize < max_allowed, \
               'Stash size %d (%d * %d) exceeds the limit %d (%d * %.2f)' % (
                   max_stashed_blocks * self.tgt.blocksize, max_stashed_blocks,
                   self.tgt.blocksize, max_allowed, cache_size,
                   stash_threshold)

    if self.version >= 3:
      self.touched_src_sha1 = self.HashBlocks(
          self.src, self.touched_src_ranges)

    # Zero out extended blocks as a workaround for bug 20881595.
    if self.tgt.extended.size() > 0:
      assert (WriteTransfersZero(out, self.tgt.extended) ==
              self.tgt.extended.size())
      total += self.tgt.extended.size()

    # We erase all the blocks on the partition that a) don't contain useful
    # data in the new image; b) will not be touched by dm-verity. Out of those
    # blocks, we erase the ones that won't be used in this update at the
    # beginning of an update. The rest would be erased at the end. This is to
    # work around the eMMC issue observed on some devices, which may otherwise
    # get starving for clean blocks and thus fail the update. (b/28347095)
    all_tgt = RangeSet(data=(0, self.tgt.total_blocks))
    all_tgt_minus_extended = all_tgt.subtract(self.tgt.extended)
    new_dontcare = all_tgt_minus_extended.subtract(self.tgt.care_map)

    erase_first = new_dontcare.subtract(self.touched_src_ranges)
    if erase_first.size() > 0:
      out.insert(0, "erase %s\n" % (erase_first.to_string_raw(),))

    erase_last = new_dontcare.subtract(erase_first)
    if erase_last.size() > 0:
      out.append("erase %s\n" % (erase_last.to_string_raw(),))

    out.insert(0, "%d\n" % (self.version,))   # format version number
    out.insert(1, "%d\n" % (total,))
    if self.version >= 2:
      # version 2 only: after the total block count, we give the number
      # of stash slots needed, and the maximum size needed (in blocks)
      out.insert(2, str(next_stash_id) + "\n")
      out.insert(3, str(max_stashed_blocks) + "\n")

    with open(prefix + ".transfer.list", "wb") as f:
      for i in out:
        f.write(i.encode("UTF-8"))

    if self.version >= 2:
      self._max_stashed_size = max_stashed_blocks * self.tgt.blocksize
      OPTIONS = common.OPTIONS
      if OPTIONS.cache_size is not None:
        max_allowed = OPTIONS.cache_size * OPTIONS.stash_threshold
        print("max stashed blocks: %d  (%d bytes), "
              "limit: %d bytes (%.2f%%)\n" % (
              max_stashed_blocks, self._max_stashed_size, max_allowed,
              self._max_stashed_size * 100.0 / max_allowed))
      else:
        print("max stashed blocks: %d  (%d bytes), limit: <unknown>\n" % (
              max_stashed_blocks, self._max_stashed_size))

  def ReviseStashSize(self):
    print("Revising stash size...")
    stashes = {}

    # Create the map between a stash and its def/use points. For example, for a
    # given stash of (idx, sr), stashes[idx] = (sr, def_cmd, use_cmd).
    for xf in self.transfers:
      # Command xf defines (stores) all the stashes in stash_before.
      for idx, sr in xf.stash_before:
        stashes[idx] = (sr, xf)

      # Record all the stashes command xf uses.
      for idx, _ in xf.use_stash:
        stashes[idx] += (xf,)

    # Compute the maximum blocks available for stash based on /cache size and
    # the threshold.
    cache_size = common.OPTIONS.cache_size
    stash_threshold = common.OPTIONS.stash_threshold
    max_allowed = cache_size * stash_threshold / self.tgt.blocksize

    stashed_blocks = 0
    new_blocks = 0

    # Now go through all the commands. Compute the required stash size on the
    # fly. If a command requires excess stash than available, it deletes the
    # stash by replacing the command that uses the stash with a "new" command
    # instead.
    for xf in self.transfers:
      replaced_cmds = []

      # xf.stash_before generates explicit stash commands.
      for idx, sr in xf.stash_before:
        if stashed_blocks + sr.size() > max_allowed:
          # We cannot stash this one for a later command. Find out the command
          # that will use this stash and replace the command with "new".
          use_cmd = stashes[idx][2]
          replaced_cmds.append(use_cmd)
          print("%10d  %9s  %s" % (sr.size(), "explicit", use_cmd))
        else:
          stashed_blocks += sr.size()

      # xf.use_stash generates free commands.
      for _, sr in xf.use_stash:
        stashed_blocks -= sr.size()

      # "move" and "diff" may introduce implicit stashes in BBOTA v3. Prior to
      # ComputePatches(), they both have the style of "diff".
      if xf.style == "diff" and self.version >= 3:
        assert xf.tgt_ranges and xf.src_ranges
        if xf.src_ranges.overlaps(xf.tgt_ranges):
          if stashed_blocks + xf.src_ranges.size() > max_allowed:
            replaced_cmds.append(xf)
            print("%10d  %9s  %s" % (xf.src_ranges.size(), "implicit", xf))

      # Replace the commands in replaced_cmds with "new"s.
      for cmd in replaced_cmds:
        # It no longer uses any commands in "use_stash". Remove the def points
        # for all those stashes.
        for idx, sr in cmd.use_stash:
          def_cmd = stashes[idx][1]
          assert (idx, sr) in def_cmd.stash_before
          def_cmd.stash_before.remove((idx, sr))

        # Add up blocks that violates space limit and print total number to
        # screen later.
        new_blocks += cmd.tgt_ranges.size()
        cmd.ConvertToNew()

    num_of_bytes = new_blocks * self.tgt.blocksize
    print("  Total %d blocks (%d bytes) are packed as new blocks due to "
          "insufficient cache size." % (new_blocks, num_of_bytes))

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
            #  - imgdiff is not disabled, and
            #  - the source and target files are monotonic (ie, the
            #    data is stored with blocks in increasing order), and
            #  - we haven't removed any blocks from the source set.
            #
            # If these conditions are satisfied then appending all the
            # blocks in the set together in order will produce a valid
            # zip file (plus possibly extra zeros in the last block),
            # which is what imgdiff needs to operate.  (imgdiff is
            # fine with extra zeros at the end of the file.)
            imgdiff = (not self.disable_imgdiff and xf.intact and
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

      # TODO: Rewrite with multiprocessing.ThreadPool?
      lock = threading.Lock()
      def diff_worker():
        while True:
          with lock:
            if not diff_q:
              return
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
                 for _ in range(self.threads)]
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
    touched = array.array("B", (0,) * self.tgt.total_blocks)

    # Imagine processing the transfers in order.
    for xf in self.transfers:
      # Check that the input blocks for this transfer haven't yet been touched.

      x = xf.src_ranges
      if self.version >= 2:
        for _, sr in xf.use_stash:
          x = x.subtract(sr)

      for s, e in x:
        # Source image could be larger. Don't check the blocks that are in the
        # source image only. Since they are not in 'touched', and won't ever
        # be touched.
        for i in range(s, min(e, self.tgt.total_blocks)):
          assert touched[i] == 0

      # Check that the output blocks for this transfer haven't yet
      # been touched, and touch all the blocks written by this
      # transfer.
      for s, e in xf.tgt_ranges:
        for i in range(s, e):
          assert touched[i] == 0
          touched[i] = 1

    # Check that we've written every target block.
    for s, e in self.tgt.care_map:
      for i in range(s, e):
        assert touched[i] == 1

  def ImproveVertexSequence(self):
    print("Improving vertex order...")

    # At this point our digraph is acyclic; we reversed any edges that
    # were backwards in the heuristically-generated sequence.  The
    # previously-generated order is still acceptable, but we hope to
    # find a better order that needs less memory for stashed data.
    # Now we do a topological sort to generate a new vertex order,
    # using a greedy algorithm to choose which vertex goes next
    # whenever we have a choice.

    # Make a copy of the edge set; this copy will get destroyed by the
    # algorithm.
    for xf in self.transfers:
      xf.incoming = xf.goes_after.copy()
      xf.outgoing = xf.goes_before.copy()

    L = []   # the new vertex order

    # S is the set of sources in the remaining graph; we always choose
    # the one that leaves the least amount of stashed data after it's
    # executed.
    S = [(u.NetStashChange(), u.order, u) for u in self.transfers
         if not u.incoming]
    heapq.heapify(S)

    while S:
      _, _, xf = heapq.heappop(S)
      L.append(xf)
      for u in xf.outgoing:
        del u.incoming[xf]
        if not u.incoming:
          heapq.heappush(S, (u.NetStashChange(), u.order, u))

    # if this fails then our graph had a cycle.
    assert len(L) == len(self.transfers)

    self.transfers = L
    for i, xf in enumerate(L):
      xf.order = i

  def RemoveBackwardEdges(self):
    print("Removing backward edges...")
    in_order = 0
    out_of_order = 0
    lost_source = 0

    for xf in self.transfers:
      lost = 0
      size = xf.src_ranges.size()
      for u in xf.goes_before:
        # xf should go before u
        if xf.order < u.order:
          # it does, hurray!
          in_order += 1
        else:
          # it doesn't, boo.  trim the blocks that u writes from xf's
          # source, so that xf can go after u.
          out_of_order += 1
          assert xf.src_ranges.overlaps(u.tgt_ranges)
          xf.src_ranges = xf.src_ranges.subtract(u.tgt_ranges)
          xf.intact = False

      if xf.style == "diff" and not xf.src_ranges:
        # nothing left to diff from; treat as new data
        xf.style = "new"

      lost = size - xf.src_ranges.size()
      lost_source += lost

    print(("  %d/%d dependencies (%.2f%%) were violated; "
           "%d source blocks removed.") %
          (out_of_order, in_order + out_of_order,
           (out_of_order * 100.0 / (in_order + out_of_order))
           if (in_order + out_of_order) else 0.0,
           lost_source))

  def ReverseBackwardEdges(self):
    print("Reversing backward edges...")
    in_order = 0
    out_of_order = 0
    stashes = 0
    stash_size = 0

    for xf in self.transfers:
      for u in xf.goes_before.copy():
        # xf should go before u
        if xf.order < u.order:
          # it does, hurray!
          in_order += 1
        else:
          # it doesn't, boo.  modify u to stash the blocks that it
          # writes that xf wants to read, and then require u to go
          # before xf.
          out_of_order += 1

          overlap = xf.src_ranges.intersect(u.tgt_ranges)
          assert overlap

          u.stash_before.append((stashes, overlap))
          xf.use_stash.append((stashes, overlap))
          stashes += 1
          stash_size += overlap.size()

          # reverse the edge direction; now xf must go after u
          del xf.goes_before[u]
          del u.goes_after[xf]
          xf.goes_after[u] = None    # value doesn't matter
          u.goes_before[xf] = None

    print(("  %d/%d dependencies (%.2f%%) were violated; "
           "%d source blocks stashed.") %
          (out_of_order, in_order + out_of_order,
           (out_of_order * 100.0 / (in_order + out_of_order))
           if (in_order + out_of_order) else 0.0,
           stash_size))

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
      xf.score = sum(xf.outgoing.values()) - sum(xf.incoming.values())

    # We use an OrderedDict instead of just a set so that the output
    # is repeatable; otherwise it would depend on the hash values of
    # the transfer objects.
    G = OrderedDict()
    for xf in self.transfers:
      G[xf] = None
    s1 = deque()  # the left side of the sequence, built from left to right
    s2 = deque()  # the right side of the sequence, built from right to left

    heap = []
    for xf in self.transfers:
      xf.heap_item = HeapItem(xf)
      heap.append(xf.heap_item)
    heapq.heapify(heap)

    sinks = set(u for u in G if not u.outgoing)
    sources = set(u for u in G if not u.incoming)

    def adjust_score(iu, delta):
      iu.score += delta
      iu.heap_item.clear()
      iu.heap_item = HeapItem(iu)
      heapq.heappush(heap, iu.heap_item)

    while G:
      # Put all sinks at the end of the sequence.
      while sinks:
        new_sinks = set()
        for u in sinks:
          if u not in G: continue
          s2.appendleft(u)
          del G[u]
          for iu in u.incoming:
            adjust_score(iu, -iu.outgoing.pop(u))
            if not iu.outgoing: new_sinks.add(iu)
        sinks = new_sinks

      # Put all the sources at the beginning of the sequence.
      while sources:
        new_sources = set()
        for u in sources:
          if u not in G: continue
          s1.append(u)
          del G[u]
          for iu in u.outgoing:
            adjust_score(iu, +iu.incoming.pop(u))
            if not iu.incoming: new_sources.add(iu)
        sources = new_sources

      if not G: break

      # Find the "best" vertex to put next.  "Best" is the one that
      # maximizes the net difference in source blocks saved we get by
      # pretending it's a source rather than a sink.

      while True:
        u = heapq.heappop(heap)
        if u and u.item in G:
          u = u.item
          break

      s1.append(u)
      del G[u]
      for iu in u.outgoing:
        adjust_score(iu, +iu.incoming.pop(u))
        if not iu.incoming: sources.add(iu)

      for iu in u.incoming:
        adjust_score(iu, -iu.outgoing.pop(u))
        if not iu.outgoing: sinks.add(iu)

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

    # Each item of source_ranges will be:
    #   - None, if that block is not used as a source,
    #   - a transfer, if one transfer uses it as a source, or
    #   - a set of transfers.
    source_ranges = []
    for b in self.transfers:
      for s, e in b.src_ranges:
        if e > len(source_ranges):
          source_ranges.extend([None] * (e-len(source_ranges)))
        for i in range(s, e):
          if source_ranges[i] is None:
            source_ranges[i] = b
          else:
            if not isinstance(source_ranges[i], set):
              source_ranges[i] = set([source_ranges[i]])
            source_ranges[i].add(b)

    for a in self.transfers:
      intersections = set()
      for s, e in a.tgt_ranges:
        for i in range(s, e):
          if i >= len(source_ranges): break
          b = source_ranges[i]
          if b is not None:
            if isinstance(b, set):
              intersections.update(b)
            else:
              intersections.add(b)

      for b in intersections:
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
    """Parse the file_map to generate all the transfers."""

    def AddTransfer(tgt_name, src_name, tgt_ranges, src_ranges, style, by_id,
                    split=False):
      """Wrapper function for adding a Transfer().

      For BBOTA v3, we need to stash source blocks for resumable feature.
      However, with the growth of file size and the shrink of the cache
      partition source blocks are too large to be stashed. If a file occupies
      too many blocks (greater than MAX_BLOCKS_PER_DIFF_TRANSFER), we split it
      into smaller pieces by getting multiple Transfer()s.

      The downside is that after splitting, we may increase the package size
      since the split pieces don't align well. According to our experiments,
      1/8 of the cache size as the per-piece limit appears to be optimal.
      Compared to the fixed 1024-block limit, it reduces the overall package
      size by 30% volantis, and 20% for angler and bullhead."""

      # We care about diff transfers only.
      if style != "diff" or not split:
        Transfer(tgt_name, src_name, tgt_ranges, src_ranges, style, by_id)
        return

      pieces = 0
      cache_size = common.OPTIONS.cache_size
      split_threshold = 0.125
      max_blocks_per_transfer = int(cache_size * split_threshold /
                                    self.tgt.blocksize)

      # Change nothing for small files.
      if (tgt_ranges.size() <= max_blocks_per_transfer and
          src_ranges.size() <= max_blocks_per_transfer):
        Transfer(tgt_name, src_name, tgt_ranges, src_ranges, style, by_id)
        return

      while (tgt_ranges.size() > max_blocks_per_transfer and
             src_ranges.size() > max_blocks_per_transfer):
        tgt_split_name = "%s-%d" % (tgt_name, pieces)
        src_split_name = "%s-%d" % (src_name, pieces)
        tgt_first = tgt_ranges.first(max_blocks_per_transfer)
        src_first = src_ranges.first(max_blocks_per_transfer)

        Transfer(tgt_split_name, src_split_name, tgt_first, src_first, style,
                 by_id)

        tgt_ranges = tgt_ranges.subtract(tgt_first)
        src_ranges = src_ranges.subtract(src_first)
        pieces += 1

      # Handle remaining blocks.
      if tgt_ranges.size() or src_ranges.size():
        # Must be both non-empty.
        assert tgt_ranges.size() and src_ranges.size()
        tgt_split_name = "%s-%d" % (tgt_name, pieces)
        src_split_name = "%s-%d" % (src_name, pieces)
        Transfer(tgt_split_name, src_split_name, tgt_ranges, src_ranges, style,
                 by_id)

    empty = RangeSet()
    for tgt_fn, tgt_ranges in self.tgt.file_map.items():
      if tgt_fn == "__ZERO":
        # the special "__ZERO" domain is all the blocks not contained
        # in any file and that are filled with zeros.  We have a
        # special transfer style for zero blocks.
        src_ranges = self.src.file_map.get("__ZERO", empty)
        AddTransfer(tgt_fn, "__ZERO", tgt_ranges, src_ranges,
                    "zero", self.transfers)
        continue

      elif tgt_fn == "__COPY":
        # "__COPY" domain includes all the blocks not contained in any
        # file and that need to be copied unconditionally to the target.
        AddTransfer(tgt_fn, None, tgt_ranges, empty, "new", self.transfers)
        continue

      elif tgt_fn in self.src.file_map:
        # Look for an exact pathname match in the source.
        AddTransfer(tgt_fn, tgt_fn, tgt_ranges, self.src.file_map[tgt_fn],
                    "diff", self.transfers, self.version >= 3)
        continue

      b = os.path.basename(tgt_fn)
      if b in self.src_basenames:
        # Look for an exact basename match in the source.
        src_fn = self.src_basenames[b]
        AddTransfer(tgt_fn, src_fn, tgt_ranges, self.src.file_map[src_fn],
                    "diff", self.transfers, self.version >= 3)
        continue

      b = re.sub("[0-9]+", "#", b)
      if b in self.src_numpatterns:
        # Look for a 'number pattern' match (a basename match after
        # all runs of digits are replaced by "#").  (This is useful
        # for .so files that contain version numbers in the filename
        # that get bumped.)
        src_fn = self.src_numpatterns[b]
        AddTransfer(tgt_fn, src_fn, tgt_ranges, self.src.file_map[src_fn],
                    "diff", self.transfers, self.version >= 3)
        continue

      AddTransfer(tgt_fn, None, tgt_ranges, empty, "new", self.transfers)

  def AbbreviateSourceNames(self):
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
