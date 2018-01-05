#!/usr/bin/env python
# -*- coding: utf-8 -*-
#====================================================
#          FILE: img2sdat.py
#       AUTHORS: xpirt - luxi78 - howellzhu
#          DATE: 2018-01-05 15:21:47 CEST
#====================================================

from __future__ import print_function

import sys, os, errno, tempfile
import common, blockimgdiff, sparse_img

__version__ = '1.6'

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
    print('Usage: img2sdat.py <system_img> [outdir] [version]\n')
    print('    <system_img>: input system image\n')
    print('    [outdir]: output directory (current directory by default)\n')
    print('    [version]: transfer list version number, will be asked by default - more info on xda thread)\n')
    print('Visit xda thread for more information.\n')
    try:
       input = raw_input
    except NameError: pass
    input('Press ENTER to exit...')
    sys.exit()

def main(argv):
    global input

    if len(sys.argv) < 3:
        outdir = './system'
    else:
        outdir = sys.argv[2] + '/system'

    if len(sys.argv) < 4:
        version = 4
        item = True
        while item:
            print('''            1. Android Lollipop 5.0
            2. Android Lollipop 5.1
            3. Android Marshmallow 6.0
            4. Android Nougat 7.0/7.1/8.0
            ''')
            try:
                input = raw_input
            except NameError: pass
            item = input('Choose system version: ')
            if item == '1':
                version = 1
                break
            elif item == '2':
                version = 2
                break
            elif item == '3':
                version = 3
                break
            elif item == '4':
                version = 4
                break
            else:
                return
    else:
        version = int(sys.argv[3])

    # Get sparse image
    image = sparse_img.SparseImage(INPUT_IMAGE, tempfile.mkstemp()[1], '0')

    # Generate output files
    b = blockimgdiff.BlockImageDiff(image, None, version)
    b.Compute(outdir)

    print('Done! Output files: %s' % os.path.dirname(outdir))
    return

if __name__ == '__main__':
    main(sys.argv)
