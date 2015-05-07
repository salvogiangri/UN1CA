#!/usr/bin/env python
#encoding:utf8
#====================================================
#          FILE: img2sdat.py
#       AUTHORS: xpirt - luxi78 - howellzhu
#          DATE: 2015-05-07 14:46:28 CST
#====================================================
import sys, blockimgdiff, sparse_img, os

def main(sysimg, outdir):
    tgt = sparse_img.SparseImage(sysimg)
    bif = blockimgdiff.BlockImageDiff(tgt, None)
    bif.Compute(outdir)
    return

if __name__ == '__main__':
    sysimg = 'system.img'
    outdir = './'
    if len(sys.argv) == 1:
        print ("\nimg2sdat - usage is: \n\n      img2sdat [system.img] [outdir]\n\n")
        print ("Visit xda thread for more information.\n")
        os.system("pause")
        sys.exit(1)
    if len(sys.argv) >= 2:
        sysimg = sys.argv[1]
    if len(sys.argv) >= 3:
        outdir = sys.argv[2] + '/'
    if len(sys.argv) >= 4:
        print ("\nimg2sdat - usage is: \n\n      img2sdat [system.img] [outdir]" % sys.argv[0])
        print ("Visit xda thread for more information.\n")
        os.system("pause")
        sys.exit(1)
    main(sysimg, outdir)
