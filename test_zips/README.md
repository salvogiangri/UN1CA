# Test ZIPs designed to test the asserts

All are signed with `key` unless otherwise specified

## wrong-footer-magic.zip
 - Footer magic corrupted
 - `footer[2:3] = 0xFF 0xFF` -> `0xFF 0xCC`

## signature-larger-than-comment.zip
 - Signature start calculated will be larger than the comment
 - `footer[0:1] = 0x15 0x06` -> `0xFF 0xFF`

## signature-inside-footer.zip
 - Signature location appears to be within footer
 - `footer[0:1] = 0x15 0x06` -> `0x01 0x00`
 - This error can not be reached under any conditions since signature must be
   both less than `FOOTER_SIZE` and larger than `comment_size`

## eocd-larger-than-length.zip
 - Comment size is longer than total length of zip
 - `footer[4:5] = 0x27 0x06` -> `0xFF 0xFF`

## wrong-eocd-magic.zip
 - EOCD has the wrong magic
 - `eocd[0:3] = 0x50 0x4B 0x05 0x06` -> `0x50 0x4C 0x05 0x06`

## multiple-ecod-magics.zip
 - Multiple EOCD magics are present
 - `0x50 0x4B 0x05 0x06` inserted 2 bytes after initial EOCD

# unsigned.zip
 - Has not been signed; is a standard zip file
 - This will fail on `footer[2:3] != 0xFF 0xFF`
