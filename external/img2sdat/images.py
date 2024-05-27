# Copyright (C) 2019 The Android Open Source Project
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
# See the License for the specific

import os
import threading
from hashlib import sha1

from rangelib import RangeSet

__all__ = ["EmptyImage", "DataImage", "FileImage"]


class Image(object):
  def RangeSha1(self, ranges):
    raise NotImplementedError

  def ReadRangeSet(self, ranges):
    raise NotImplementedError

  def TotalSha1(self, include_clobbered_blocks=False):
    raise NotImplementedError

  def WriteRangeDataToFd(self, ranges, fd):
    raise NotImplementedError


class EmptyImage(Image):
  """A zero-length image."""

  def __init__(self):
    self.blocksize = 4096
    self.care_map = RangeSet()
    self.clobbered_blocks = RangeSet()
    self.extended = RangeSet()
    self.total_blocks = 0
    self.file_map = {}
    self.hashtree_info = None

  def RangeSha1(self, ranges):
    return sha1().hexdigest()

  def ReadRangeSet(self, ranges):
    return ()

  def TotalSha1(self, include_clobbered_blocks=False):
    # EmptyImage always carries empty clobbered_blocks, so
    # include_clobbered_blocks can be ignored.
    assert self.clobbered_blocks.size() == 0
    return sha1().hexdigest()

  def WriteRangeDataToFd(self, ranges, fd):
    raise ValueError("Can't write data from EmptyImage to file")


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

    self.total_blocks = len(self.data) // self.blocksize
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

  def _GetRangeData(self, ranges):
    for s, e in ranges:
      yield self.data[s*self.blocksize:e*self.blocksize]

  def RangeSha1(self, ranges):
    h = sha1()
    for data in self._GetRangeData(ranges): # pylint: disable=not-an-iterable
      h.update(data)
    return h.hexdigest()

  def ReadRangeSet(self, ranges):
    return list(self._GetRangeData(ranges))

  def TotalSha1(self, include_clobbered_blocks=False):
    if not include_clobbered_blocks:
      return self.RangeSha1(self.care_map.subtract(self.clobbered_blocks))
    return sha1(self.data).hexdigest()

  def WriteRangeDataToFd(self, ranges, fd):
    for data in self._GetRangeData(ranges): # pylint: disable=not-an-iterable
      fd.write(data)


class FileImage(Image):
  """An image wrapped around a raw image file."""

  def __init__(self, path):
    self.path = path
    self.blocksize = 4096
    self._file_size = os.path.getsize(self.path)
    self._file = open(self.path, 'rb')

    if self._file_size % self.blocksize != 0:
      raise ValueError("Size of file %s must be multiple of %d bytes, but is %d"
                       % self.path, self.blocksize, self._file_size)

    self.total_blocks = self._file_size // self.blocksize
    self.care_map = RangeSet(data=(0, self.total_blocks))
    self.clobbered_blocks = RangeSet()
    self.extended = RangeSet()

    self.generator_lock = threading.Lock()

    zero_blocks = []
    nonzero_blocks = []
    reference = '\0' * self.blocksize

    for i in range(self.total_blocks):
      d = self._file.read(self.blocksize)
      if d == reference:
        zero_blocks.append(i)
        zero_blocks.append(i+1)
      else:
        nonzero_blocks.append(i)
        nonzero_blocks.append(i+1)

    assert zero_blocks or nonzero_blocks

    self.file_map = {}
    if zero_blocks:
      self.file_map["__ZERO"] = RangeSet(data=zero_blocks)
    if nonzero_blocks:
      self.file_map["__NONZERO"] = RangeSet(data=nonzero_blocks)

  def __del__(self):
    self._file.close()

  def _GetRangeData(self, ranges):
    # Use a lock to protect the generator so that we will not run two
    # instances of this generator on the same object simultaneously.
    with self.generator_lock:
      for s, e in ranges:
        self._file.seek(s * self.blocksize)
        for _ in range(s, e):
          yield self._file.read(self.blocksize)

  def RangeSha1(self, ranges):
    h = sha1()
    for data in self._GetRangeData(ranges): # pylint: disable=not-an-iterable
      h.update(data)
    return h.hexdigest()

  def ReadRangeSet(self, ranges):
    return list(self._GetRangeData(ranges))

  def TotalSha1(self, include_clobbered_blocks=False):
    assert not self.clobbered_blocks
    return self.RangeSha1(self.care_map)

  def WriteRangeDataToFd(self, ranges, fd):
    for data in self._GetRangeData(ranges): # pylint: disable=not-an-iterable
      fd.write(data)
