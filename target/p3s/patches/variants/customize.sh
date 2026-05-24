# Firmware
if [ -d "$WORK_DIR/vendor/firmware/SM-G998B" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-G998B\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-G998B\""
SET_METADATA "vendor" "firmware/SM-G998B" 0 2000 755 "u:object_r:vendor_firmware_file:s0"

while IFS= read -r f; do
    BLOB="$(basename "$f")"
    if [[ "$BLOB" == "libsn100u_fw.so" ]]; then
        BLOB="nfc/$BLOB"
        if [ -d "$WORK_DIR/vendor/firmware/SM-G998B/nfc" ]; then
            EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-G998B/nfc\""
        fi
        EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-G998B/nfc\""
        SET_METADATA "vendor" "firmware/SM-G998B/nfc" 0 2000 755 "u:object_r:vendor_firmware_file:s0"
    fi

    LABEL="u:object_r:vendor_firmware_file:s0"
    if [[ "$BLOB" == "NPU.bin" ]]; then
        LABEL="u:object_r:vendor_npu_firmware_file:s0"
    fi

    LOG "- Moving /vendor/firmware/$BLOB to /vendor/firmware/SM-G998B/$BLOB"
    EVAL "mv \"$WORK_DIR/vendor/firmware/$BLOB\" \"$WORK_DIR/vendor/firmware/SM-G998B/$BLOB\""
    SET_METADATA "vendor" "firmware/SM-G998B/$BLOB" 0 0 644 "$LABEL"

    LOG "- Creating dummy /vendor/firmware/$BLOB"
    EVAL "touch \"$WORK_DIR/vendor/firmware/$BLOB\""

    unset BLOB LABEL
done < <(find "$MODPATH/vendor/firmware/SM-G998N" -type f ! -path "*wifi*")

if [ -d "$WORK_DIR/vendor/firmware/SM-G998B/wifi" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-G998B/wifi\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-G998B/wifi\""
SET_METADATA "vendor" "firmware/SM-G998B/wifi" 0 2000 755 "u:object_r:vendor_firmware_file:s0"

for f in "nvram.txt_1wk_es40_c0" "nvram.txt_1wk_es41_c0" \
        "nvram.txt_4389_3321" "nvram.txt_ES32_semco_c0" "nvram.txt_ES40_semco_c1"; do
    LOG "- Moving /vendor/firmware/wifi/$f to /vendor/firmware/SM-G998B/wifi/$f"
    EVAL "mv \"$WORK_DIR/vendor/firmware/wifi/$f\" \"$WORK_DIR/vendor/firmware/SM-G998B/wifi/$f\""
    SET_METADATA "vendor" "firmware/SM-G998B/wifi/$f" 0 0 644 "u:object_r:vendor_firmware_file:s0"

    LOG "- Creating dummy /vendor/firmware/wifi/$f"
    EVAL "touch \"$WORK_DIR/vendor/firmware/wifi/$f\""
done

LOG "- Creating dummy /vendor/firmware/wifi/nvram_ES40_semco_c1"
EVAL "touch \"$WORK_DIR/vendor/firmware/wifi/nvram_ES40_semco_c1\""
SET_METADATA "vendor" "firmware/wifi/nvram_ES40_semco_c1" 0 0 644 "u:object_r:vendor_firmware_file:s0"

# SELinux
LOG "- Adding SELinux entries"
{
    echo "(allow init_30_0 tee_file (dir (mounton)))"
    echo "(allow priv_app_30_0 tee_file (dir (getattr)))"
    echo "(allow init_30_0 vendor_firmware_file (file (mounton)))"
    echo "(allow priv_app_30_0 vendor_firmware_file (file (getattr)))"
    echo "(allow init_30_0 vendor_npu_firmware_file (file (mounton)))"
    echo "(allow priv_app_30_0 vendor_npu_firmware_file (file (getattr)))"
} >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
