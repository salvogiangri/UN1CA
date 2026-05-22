# Enable RAW Support
# Before: [cbz r0, #0x15612a]
# After: [nop]
HEX_PATCH "$WORK_DIR/vendor/lib/libexynoscamera3.so" "f0b12649" "00bf2649"

# Before: [tbz w8, #0, 0x59d448]
# After: [nop]
HEX_PATCH "$WORK_DIR/vendor/lib64/libexynoscamera3.so" "88020036610d00f0" "1f2003d5610d00f0"
