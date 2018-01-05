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

import bisect
import os
import sys
import struct
from hashlib import sha1

import rangelib


class SparseImage(object):
  """Wraps a sparse image file into an image object.

  Wraps a sparse image file (and optional file map and clobbered_blocks) into
  an image object suitable for passing to BlockImageDiff. file_map contains
  the mapping between files and their blocks. clobbered_blocks contains the set
  of blocks that should be always written to the target regardless of the old
  contents (i.e. copying instead of patching). clobbered_blocks should be in
  the form of a string like "0" or "0 1-5 8".
  """

  def __init__(self, simg_fn, file_map_fn=None, clobbered_blocks=None,
               mode="rb", build_map=True):
    self.simg_f = f = open(simg_fn, mode)

    header_bin = f.read(28)
    header = struct.unpack("<I4H4I", header_bin)

    magic = header[0]
    major_version = header[1]
    minor_version = header[2]
    file_hdr_sz = header[3]
    chunk_hdr_sz = header[4]
    self.blocksize = blk_sz = header[5]
    self.total_blocks = total_blks = header[6]
    self.total_chunks = total_chunks = header[7]

    if magic != 0xED26FF3A:
      raise ValueError("Magic should be 0xED26FF3A but is 0x%08X" % (magic,))
    if major_version != 1 or minor_version != 0:
      raise ValueError("I know about version 1.0, but this is version %u.%u" %
                       (major_version, minor_version))
    if file_hdr_sz != 28:
      raise ValueError("File header size was expected to be 28, but is %u." %
                       (file_hdr_sz,))
    if chunk_hdr_sz != 12:
      raise ValueError("Chunk header size was expected to be 12, but is %u." %
                       (chunk_hdr_sz,))

    print("Total of %u %u-byte output blocks in %u input chunks."
          % (total_blks, blk_sz, total_chunks))

    if not build_map:
      return

    pos = 0   # in blocks
    care_data = []
    self.offset_map = offset_map = []
    self.clobbered_blocks = rangelib.RangeSet(data=clobbered_blocks)

    for i in range(total_chunks):
      header_bin = f.read(12)
      header = struct.unpack("<2H2I", header_bin)
      chunk_type = header[0]
      chunk_sz = header[2]
      total_sz = header[3]
      data_sz = total_sz - 12

      if chunk_type == 0xCAC1:
        if data_sz != (chunk_sz * blk_sz):
          raise ValueError(
              "Raw chunk input size (%u) does not match output size (%u)" %
              (data_sz, chunk_sz * blk_sz))
        else:
          care_data.append(pos)
          care_data.append(pos + chunk_sz)
          offset_map.append((pos, chunk_sz, f.tell(), None))
          pos += chunk_sz
          f.seek(data_sz, os.SEEK_CUR)

      elif chunk_type == 0xCAC2:
        fill_data = f.read(4)
        care_data.append(pos)
        care_data.append(pos + chunk_sz)
        offset_map.append((pos, chunk_sz, None, fill_data))
        pos += chunk_sz

      elif chunk_type == 0xCAC3:
        if data_sz != 0:
          raise ValueError("Don't care chunk input size is non-zero (%u)" %
                           (data_sz))
        else:
          pos += chunk_sz

      elif chunk_type == 0xCAC4:
        raise ValueError("CRC32 chunks are not supported")

      else:
        raise ValueError("Unknown chunk type 0x%04X not supported" %
                         (chunk_type,))

    self.care_map = rangelib.RangeSet(care_data)
    self.offset_index = [i[0] for i in offset_map]

    # Bug: 20881595
    # Introduce extended blocks as a workaround for the bug. dm-verity may
    # touch blocks that are not in the care_map due to block device
    # read-ahead. It will fail if such blocks contain non-zeroes. We zero out
    # the extended blocks explicitly to avoid dm-verity failures. 512 blocks
    # are the maximum read-ahead we configure for dm-verity block devices.
    extended = self.care_map.extend(512)
    all_blocks = rangelib.RangeSet(data=(0, self.total_blocks))
    extended = extended.intersect(all_blocks).subtract(self.care_map)
    self.extended = extended

    if file_map_fn:
      self.LoadFileBlockMap(file_map_fn, self.clobbered_blocks)
    else:
      self.file_map = {"__DATA": self.care_map}

  def AppendFillChunk(self, data, blocks):
    f = self.simg_f

    # Append a fill chunk
    f.seek(0, os.SEEK_END)
    f.write(struct.pack("<2H3I", 0xCAC2, 0, blocks, 16, data))

    # Update the sparse header
    self.total_blocks += blocks
    self.total_chunks += 1

    f.seek(16, os.SEEK_SET)
    f.write(struct.pack("<2I", self.total_blocks, self.total_chunks))

  def ReadRangeSet(self, ranges):
    return [d for d in self._GetRangeData(ranges)]

  def TotalSha1(self, include_clobbered_blocks=False):
    """Return the SHA-1 hash of all data in the 'care' regions.

    If include_clobbered_blocks is True, it returns the hash including the
    clobbered_blocks."""
    ranges = self.care_map
    if not include_clobbered_blocks:
      ranges = ranges.subtract(self.clobbered_blocks)
    h = sha1()
    for d in self._GetRangeData(ranges):
      h.update(d)
    return h.hexdigest()

  def _GetRangeData(self, ranges):
    """Generator that produces all the image data in 'ranges'.  The
    number of individual pieces returned is arbitrary (and in
    particular is not necessarily equal to the number of ranges in
    'ranges'.

    This generator is stateful -- it depends on the open file object
    contained in this SparseImage, so you should not try to run two
    instances of this generator on the same object simultaneously."""

    f = self.simg_f
    for s, e in ranges:
      to_read = e-s
      idx = bisect.bisect_right(self.offset_index, s) - 1
      chunk_start, chunk_len, filepos, fill_data = self.offset_map[idx]

      # for the first chunk we may be starting partway through it.
      remain = chunk_len - (s - chunk_start)
      this_read = min(remain, to_read)
      if filepos is not None:
        p = filepos + ((s - chunk_start) * self.blocksize)
        f.seek(p, os.SEEK_SET)
        yield f.read(this_read * self.blocksize)
      else:
        yield fill_data * (this_read * (self.blocksize >> 2))
      to_read -= this_read

      while to_read > 0:
        # continue with following chunks if this range spans multiple chunks.
        idx += 1
        chunk_start, chunk_len, filepos, fill_data = self.offset_map[idx]
        this_read = min(chunk_len, to_read)
        if filepos is not None:
          f.seek(filepos, os.SEEK_SET)
          yield f.read(this_read * self.blocksize)
        else:
          yield fill_data * (this_read * (self.blocksize >> 2))
        to_read -= this_read

  def LoadFileBlockMap(self, fn, clobbered_blocks):
    remaining = self.care_map
    self.file_map = out = {}

    with open(fn) as f:
      for line in f:
        fn, ranges = line.split(None, 1)
        ranges = rangelib.RangeSet.parse(ranges)
        out[fn] = ranges
        assert ranges.size() == ranges.intersect(remaining).size()

        # Currently we assume that blocks in clobbered_blocks are not part of
        # any file.
        assert not clobbered_blocks.overlaps(ranges)
        remaining = remaining.subtract(ranges)

    remaining = remaining.subtract(clobbered_blocks)

    # For all the remaining blocks in the care_map (ie, those that
    # aren't part of the data for any file nor part of the clobbered_blocks),
    # divide them into blocks that are all zero and blocks that aren't.
    # (Zero blocks are handled specially because (1) there are usually
    # a lot of them and (2) bsdiff handles files with long sequences of
    # repeated bytes especially poorly.)

    zero_blocks = []
    nonzero_blocks = []
    if sys.version_info[:2] >= (3, 0):
        reference = bytes('\0' * self.blocksize, encoding="UTF-8")
    else:
        reference = '\0' * self.blocksize

    # Workaround for bug 23227672. For squashfs, we don't have a system.map. So
    # the whole system image will be treated as a single file. But for some
    # unknown bug, the updater will be killed due to OOM when writing back the
    # patched image to flash (observed on lenok-userdebug MEA49). Prior to
    # getting a real fix, we evenly divide the non-zero blocks into smaller
    # groups (currently 1024 blocks or 4MB per group).
    # Bug: 23227672
    MAX_BLOCKS_PER_GROUP = 1024
    nonzero_groups = []

    f = self.simg_f
    for s, e in remaining:
      for b in range(s, e):
        idx = bisect.bisect_right(self.offset_index, b) - 1
        chunk_start, _, filepos, fill_data = self.offset_map[idx]
        if filepos is not None:
          filepos += (b-chunk_start) * self.blocksize
          f.seek(filepos, os.SEEK_SET)
          data = f.read(self.blocksize)
        else:
          if fill_data == reference[:4]:   # fill with all zeros
            data = reference
          else:
            data = None

        if data == reference:
          zero_blocks.append(b)
          zero_blocks.append(b+1)
        else:
          nonzero_blocks.append(b)
          nonzero_blocks.append(b+1)

          if len(nonzero_blocks) >= MAX_BLOCKS_PER_GROUP:
            nonzero_groups.append(nonzero_blocks)
            # Clear the list.
            nonzero_blocks = []

    if nonzero_blocks:
      nonzero_groups.append(nonzero_blocks)
      nonzero_blocks = []

    assert zero_blocks or nonzero_groups or clobbered_blocks

    if zero_blocks:
      out["__ZERO"] = rangelib.RangeSet(data=zero_blocks)
    if nonzero_groups:
      for i, blocks in enumerate(nonzero_groups):
        out["__NONZERO-%d" % i] = rangelib.RangeSet(data=blocks)
    if clobbered_blocks:
      out["__COPY"] = clobbered_blocks

  def ResetFileMap(self):
    """Throw away the file map and treat the entire image as
    undifferentiated data."""
    self.file_map = {"__DATA": self.care_map}
