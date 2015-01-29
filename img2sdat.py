import sys
import blockimgdiff
import sparse_img

def main(sysimg, outdir):
    print 'img2sdat tools from Howellzhu@gmail.com'
    tgt = sparse_img.SparseImage(sysimg)
    bif = blockimgdiff.BlockImageDiff(tgt, None)
    bif.Compute('system', outdir)
    return


if __name__ == '__main__':
    sysimg = 'system.img'
    outdir = './'
    if len(sys.argv) >= 2:
        sysimg = sys.argv[1]
    if len(sys.argv) >= 3:
        outdir = sys.argv[2] + '/'
    if len(sys.argv) >= 4:
        print 'Usage: %s [system.img] [outdir]' % sys.argv[0]
        sys.exit(1)
    main(sysimg, outdir)
