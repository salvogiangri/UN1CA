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
import heapq
import itertools
__all__ = ["RangeSet"]
class RangeSet(object):
  """A RangeSet represents a set of nonoverlapping ranges on the
  integers (ie, a set of integers, but efficient when the set contains
  lots of runs."""
  def __init__(self, data=None):
    if data:
      self.data = tuple(self._remove_pairs(data))
    else:
      self.data = ()
  def __iter__(self):
    for i in range(0, len(self.data), 2):
      yield self.data[i:i+2]
  def __eq__(self, other):
    return self.data == other.data
  def __ne__(self, other):
    return self.data != other.data
  def __nonzero__(self):
    return bool(self.data)
  def __str__(self):
    if not self.data:
      return "empty"
    else:
      return self.to_string()
  @classmethod
  def parse(cls, text):
    """Parse a text string consisting of a space-separated list of
    blocks and ranges, eg "10-20 30 35-40".  Ranges are interpreted to
    include both their ends (so the above example represents 18
    individual blocks.  Returns a RangeSet object.
    If the input has all its blocks in increasing order, then returned
    RangeSet will have an extra attribute 'monotonic' that is set to
    True.  For example the input "10-20 30" is monotonic, but the input
    "15-20 30 10-14" is not, even though they represent the same set
    of blocks (and the two RangeSets will compare equal with ==).
    """
    data = []
    last = -1
    monotonic = True
    for p in text.split():
      if "-" in p:
        s, e = p.split("-")
        data.append(int(s))
        data.append(int(e)+1)
        if last <= s <= e:
          last = e
        else:
          monotonic = False
      else:
        s = int(p)
        data.append(s)
        data.append(s+1)
        if last <= s:
          last = s+1
        else:
          monotonic = True
    data.sort()
    r = RangeSet(cls._remove_pairs(data))
    r.monotonic = monotonic
    return r
  @staticmethod
  def _remove_pairs(source):
    last = None
    for i in source:
      if i == last:
        last = None
      else:
        if last is not None:
          yield last
        last = i
    if last is not None:
      yield last
  def to_string(self):
    out = []
    for i in range(0, len(self.data), 2):
      s, e = self.data[i:i+2]
      if e == s+1:
        out.append(str(s))
      else:
        out.append(str(s) + "-" + str(e-1))
    return " ".join(out)
  def to_string_raw(self):
    return str(len(self.data)) + "," + ",".join(str(i) for i in self.data)
  def union(self, other):
    """Return a new RangeSet representing the union of this RangeSet
    with the argument."""
    out = []
    z = 0
    for p, d in heapq.merge(zip(self.data, itertools.cycle((+1, -1))),
                            zip(other.data, itertools.cycle((+1, -1)))):
      if (z == 0 and d == 1) or (z == 1 and d == -1):
        out.append(p)
      z += d
    return RangeSet(data=out)
  def intersect(self, other):
    """Return a new RangeSet representing the intersection of this
    RangeSet with the argument."""
    out = []
    z = 0
    for p, d in heapq.merge(zip(self.data, itertools.cycle((+1, -1))),
                            zip(other.data, itertools.cycle((+1, -1)))):
      if (z == 1 and d == 1) or (z == 2 and d == -1):
        out.append(p)
      z += d
    return RangeSet(data=out)
  def subtract(self, other):
    """Return a new RangeSet representing subtracting the argument
    from this RangeSet."""
    out = []
    z = 0
    for p, d in heapq.merge(zip(self.data, itertools.cycle((+1, -1))),
                            zip(other.data, itertools.cycle((-1, +1)))):
      if (z == 0 and d == 1) or (z == 1 and d == -1):
        out.append(p)
      z += d
    return RangeSet(data=out)
  def overlaps(self, other):
    """Returns true if the argument has a nonempty overlap with this
    RangeSet."""
    # This is like intersect, but we can stop as soon as we discover the
    # output is going to be nonempty.
    z = 0
    for p, d in heapq.merge(zip(self.data, itertools.cycle((+1, -1))),
                            zip(other.data, itertools.cycle((+1, -1)))):
      if (z == 1 and d == 1) or (z == 2 and d == -1):
        return True
      z += d
    return False
  def size(self):
    """Returns the total size of the RangeSet (ie, how many integers
    are in the set)."""
    total = 0
    for i, p in enumerate(self.data):
      if i % 2:
        total += p
      else:
        total -= p
    return total