#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#====================================================
#          FILE: img2sdat.py
#       AUTHORS: xpirt - luxi78 - howellzhu
#          DATE: 2018-05-25 12:19:12 CEST
#====================================================

import os, tempfile
import common, blockimgdiff, images, sparse_img

def main(INPUT_IMAGE, OUTDIR='.', VERSION=4):
    __version__ = '2.0'

    print('img2sdat binary - version: %s\n' % __version__)
        
    if not os.path.isdir(OUTDIR):
        os.makedirs(OUTDIR)

    OUTDIR = OUTDIR + '/'+ os.path.splitext(os.path.basename(INPUT_IMAGE))[0]

    common.OPTIONS.cache_size = 4 * 4096

    # Get image
    if IsSparseImage(INPUT_IMAGE):
        image = sparse_img.SparseImage(INPUT_IMAGE, tempfile.mkstemp()[1], '0')
    else:
        image = images.FileImage(INPUT_IMAGE)

    # Generate output files
    b = blockimgdiff.BlockImageDiff(image, None, VERSION)
    b.Compute(OUTDIR)

    print('Done! Output files: %s' % os.path.dirname(OUTDIR))
    return

def IsSparseImage(INPUT_IMAGE):
    if not os.path.exists(INPUT_IMAGE):
        return False
    with open(INPUT_IMAGE, 'rb') as fp:
        # Magic for android sparse image format
        # https://source.android.com/devices/bootloader/images
        return fp.read(4) == b'\x3A\xFF\x26\xED'

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Visit xda thread for more information.')
    parser.add_argument('image', help='input system image')
    parser.add_argument('-o', '--outdir', help='output directory (current directory by default)')
    parser.add_argument('-v', '--version', help='transfer list version number, will be asked by default - more info on xda thread)')

    args = parser.parse_args()

    INPUT_IMAGE = args.image

    if args.outdir:
        OUTDIR = args.outdir
    else:
        OUTDIR = '.'

    if args.version:
        VERSION = int(args.version)
    else:
        VERSION = 4

    main(INPUT_IMAGE, OUTDIR, VERSION)
