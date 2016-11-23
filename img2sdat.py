#!/usr/bin/env python
# -*- coding: utf-8 -*-
#====================================================
#          FILE: img2sdat.py
#       AUTHORS: xpirt - luxi78 - howellzhu
#          DATE: 2016-11-23 16:20:11 CST
#====================================================

import sys, os, errno, tempfile
import common, blockimgdiff, sparse_img

__version__ = '1.0'

if sys.hexversion < 0x02070000:
    print >> sys.stderr, "Python 2.7 or newer is required."
    try:
       input = raw_input
    except NameError: pass
    input('Press ENTER to exit...')
    sys.exit(1)
else:
    print('img2sdat binary - version: %s\n' % __version__)

try:
    INPUT_IMAGE = str(sys.argv[1])
except IndexError:
    print('Usage: img2sdat.py <system_img>\n')
    print('    <system_img>: input system image\n')
    print("Visit xda thread for more information.\n")
    try:
       input = raw_input
    except NameError: pass
    input('Press ENTER to exit...')
    sys.exit()

def main(argv):
    # Get sparse image
    input_image = sparse_img.SparseImage(INPUT_IMAGE, tempfile.mkstemp()[1], '0')
    
    # Generate output files
    b = blockimgdiff.BlockImageDiff(input_image, None)
    b.Compute('system')
    
    print('Done! Output files: %s' % os.path.dirname(__file__))
    return

if __name__ == '__main__':
    main(sys.argv)
