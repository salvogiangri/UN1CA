# Copyright (c) 2026 Majaahh, 7jari
# SPDX-License-Identifier: GPL-3.0-or-later

# Firmware
if [ -d "$WORK_DIR/vendor/firmware/SM-A057F" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-A057F\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-A057F\""
SET_METADATA "vendor" "firmware/SM-A057F" 0 2000 755 "u:object_r:vendor_firmware_file:s0"

for f in "ipa_fws.b01" "ipa_fws.elf" "ipa_fws.mdt" "wlanmdsp.mbn"; do
    LOG "- Moving /vendor/firmware/$f to /vendor/firmware/SM-A057F/$f"
    EVAL "mv \"$WORK_DIR/vendor/firmware/$f\" \"$WORK_DIR/vendor/firmware/SM-A057F/$f\""
    SET_METADATA "vendor" "firmware/SM-A057F/$f" 0 0 644 "u:object_r:vendor_firmware_file:s0"

    LOG "- Creating dummy /vendor/firmware/$f"
    EVAL "touch \"$WORK_DIR/vendor/firmware/$f\""
done

LOG "- Adding SELinux entries"
{
    echo "(allow init_33_0 vendor_firmware_file (file (mounton)))"
    echo "(allow priv_app_33_0 vendor_firmware_file (file (getattr)))"
} >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil" || return 1
