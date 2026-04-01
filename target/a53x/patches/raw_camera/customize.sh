# Enable RAW Support
# Before: [
#  movs r0,#0x4
#  ldr r1,[0x000f4fb4]
#  ldr r2,[0x000f4fb8]
#  ldr r3,[0x000f4fbc]
#  add r1,pc
# ]
# After: [
#  str.w r0,[r5,#0x8c8]
#  nop
#  nop
#  nop
# ]
HEX_PATCH "$WORK_DIR/vendor/lib/libexynoscamera3.so" \
    "04201649164a174b7944" \
    "c5f8c80800bf00bf00bf"

# Before: [
#  mov x6,sp
#  mov w0,#0x4
#  mov w5,w19
#  bl 0x0040acc0
# ]
# After: [
#  ldr w0,[x20, #0xa20]
#  orr w0,w0,#0x10
#  str w0,[x20, #0xa20]
#  nop
# ]
HEX_PATCH "$WORK_DIR/vendor/lib64/libexynoscamera3.so" \
    "e603009180008052e503132aa7d20794" \
    "80224ab900001c3280220ab91f2003d5"

LOG_STEP_IN "- Creating required permissions"
LOG "- Generating /vendor/etc/permissions/android.hardware.camera.raw.xml"
# https://android.googlesource.com/platform/frameworks/native/+/refs/tags/android-16.0.0_r1/data/etc/android.hardware.camera.raw.xml
{
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    echo "<!--"
    echo "    Copyright (c) 2014 The Android Open Source Project"
    echo "    SPDX-License-Identifier: Apache-2.0"
    echo "-->"
    echo "<permissions>"
    echo "    <feature name=\"android.hardware.camera.capability.raw\" />"
    echo "</permissions>"
} >> "$WORK_DIR/vendor/etc/permissions/android.hardware.camera.raw.xml"

SET_METADATA "vendor" "etc/permissions/android.hardware.camera.raw.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT
