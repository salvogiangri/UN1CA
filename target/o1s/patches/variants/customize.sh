# Firmware
if [ -d "$WORK_DIR/vendor/firmware/SM-G991B" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-G991B\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-G991B\""
SET_METADATA "vendor" "firmware/SM-G991B" 0 2000 755 "u:object_r:vendor_firmware_file:s0"

while IFS= read -r f; do
    BLOB="$(basename "$f")"
    if [[ "$BLOB" == "libsn100u_fw.so" ]]; then
        BLOB="nfc/$BLOB"
        if [ -d "$WORK_DIR/vendor/firmware/SM-G991B/nfc" ]; then
            EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-G991B/nfc\""
        fi
        EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-G991B/nfc\""
        SET_METADATA "vendor" "firmware/SM-G991B/nfc" 0 2000 755 "u:object_r:vendor_firmware_file:s0"
    fi

    LABEL="u:object_r:vendor_firmware_file:s0"
    if [[ "$BLOB" == "NPU.bin" ]]; then
        LABEL="u:object_r:vendor_npu_firmware_file:s0"
    fi

    LOG "- Moving /vendor/firmware/$BLOB to /vendor/firmware/SM-G991B/$BLOB"
    EVAL "mv \"$WORK_DIR/vendor/firmware/$BLOB\" \"$WORK_DIR/vendor/firmware/SM-G991B/$BLOB\""
    SET_METADATA "vendor" "firmware/SM-G991B/$BLOB" 0 0 644 "$LABEL"

    LOG "- Creating dummy /vendor/firmware/$BLOB"
    EVAL "touch \"$WORK_DIR/vendor/firmware/$BLOB\""

    unset BLOB LABEL
done < <(find "$MODPATH/vendor/firmware/SM-G991N" -type f)

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
