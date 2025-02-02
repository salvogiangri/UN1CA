SKIPUNZIP=1

cp -a --preserve=all "$SRC_DIR/target/$TARGET_CODENAME/patches/china/vendor/"* "$WORK_DIR/odm"
if ! grep -q "firmware" "$WORK_DIR/configs/file_context-odm"; then
    {
        echo "/odm/firmware u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/CAMERA_ICP\.b20 u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/CAMERA_ICP\.mbn u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/CAMERA_ICP\.mdt u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/a740_zap\.b02 u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/a740_zap\.mbn u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/a740_zap\.mdt u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/evass\.b19 u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/evass\.mbn u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/evass\.mdt u:object_r:vendor_firmware_file:s0"
        echo "/odm/firmware/vpu30_4v\.mbn u:object_r:vendor_firmware_file:s0"
    } >> "$WORK_DIR/configs/file_context-odm"
fi
if ! grep -q "firmware" "$WORK_DIR/configs/fs_config-odm"; then
    {
        echo "odm/firmware 0 0 755 capabilities=0x0"
        echo "odm/firmware/CAMERA_ICP.b20 0 0 644 capabilities=0x0"
        echo "odm/firmware/CAMERA_ICP.mbn 0 0 644 capabilities=0x0"
        echo "odm/firmware/CAMERA_ICP.mdt 0 0 644 capabilities=0x0"
        echo "odm/firmware/a740_zap.b02 0 0 644 capabilities=0x0"
        echo "odm/firmware/a740_zap.mbn 0 0 644 capabilities=0x0"
        echo "odm/firmware/a740_zap.mdt 0 0 644 capabilities=0x0"
        echo "odm/firmware/evass.b19 0 0 644 capabilities=0x0"
        echo "odm/firmware/evass.mbn 0 0 644 capabilities=0x0"
        echo "odm/firmware/evass.mdt 0 0 644 capabilities=0x0"
        echo "odm/firmware/vpu30_4v.mbn 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-odm"
fi
