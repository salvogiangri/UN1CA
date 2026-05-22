# Enable RAW Support
# Before: [cbz r0, #0x15a15a]
# After: [nop]
HEX_PATCH "$WORK_DIR/vendor/lib/libexynoscamera3.so" "f0b12649" "00bf2649"

# Before: [tbz w8, #0, 0x5a2fd4]
# After: [nop]
HEX_PATCH "$WORK_DIR/vendor/lib64/libexynoscamera3.so" "88020036c10d00b0" "1f2003d5c10d00b0"
