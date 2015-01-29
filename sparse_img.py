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
import bisect
import os
import sys
import struct
import pprint
from hashlib import sha1
from rangelib import *
class SparseImage(object):
  """Wraps a sparse image file (and optional file map) into an image
  object suitable for passing to BlockImageDiff."""
  def __init__(self, simg_fn, file_map_fn=None):
    try:
      self.simg_f = f = open(simg_fn, "rb")
    except FileNotFoundError:
      print("invalid file or path")
      os.system("pause")
      sys.exit()
    header_bin = f.read(28)
    header = struct.unpack("<I4H4I", header_bin)
    magic = header[0]
    major_version = header[1]
    minor_version = header[2]
    file_hdr_sz = header[3]
    chunk_hdr_sz = header[4]
    self.blocksize = blk_sz = header[5]
    self.total_blocks = total_blks = header[6]
    total_chunks = header[7]
    image_checksum = header[8]
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
    pos = 0   # in blocks
    care_data = []
    self.offset_map = offset_map = []
    for i in range(total_chunks):
      header_bin = f.read(12)
      header = struct.unpack("<2H2I", header_bin)
      chunk_type = header[0]
      reserved1 = header[1]
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
    self.care_map = RangeSet(care_data)
    self.offset_index = [i[0] for i in offset_map]
    if file_map_fn:
      self.LoadFileBlockMap(file_map_fn)
    else:
      self.file_map = {"__DATA": self.care_map}
  def ReadRangeSet(self, ranges):
    return [d for d in self._GetRangeData(ranges)]
  def TotalSha1(self):
    """Return the SHA-1 hash of all data in the 'care' regions of this image."""
    h = sha1()
    for d in self._GetRangeData(self.care_map):
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
  def LoadFileBlockMap(self, fn):
    remaining = self.care_map
    self.file_map = out = {}
    with open(fn) as f:
      for line in f:
        fn, ranges = line.split(None, 1)
        ranges = RangeSet.parse(ranges)
        out[fn] = ranges
        assert ranges.size() == ranges.intersect(remaining).size()
        remaining = remaining.subtract(ranges)
    # For all the remaining blocks in the care_map (ie, those that
    # aren't part of the data for any file), divide them into blocks
    # that are all zero and blocks that aren't.  (Zero blocks are
    # handled specially because (1) there are usually a lot of them
    # and (2) bsdiff handles files with long sequences of repeated
    # bytes especially poorly.)
    zero_blocks = []
    nonzero_blocks = []
    reference = '\0' * self.blocksize
    f = self.simg_f
    for s, e in remaining:
      for b in range(s, e):
        idx = bisect.bisect_right(self.offset_index, b) - 1
        chunk_start, chunk_len, filepos, fill_data = self.offset_map[idx]
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
    out["__ZERO"] = RangeSet(data=zero_blocks)
    out["__NONZERO"] = RangeSet(data=nonzero_blocks)
  def ResetFileMap(self):
    """Throw away the file map and treat the entire image as
    undifferentiated data."""
    self.file_map = {"__DATA": self.care_map}
