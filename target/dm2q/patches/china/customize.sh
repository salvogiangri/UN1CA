SKIPUNZIP=1

mkdir -p "$WORK_DIR/odm/firmware"
cp -a --preserve=all "$SRC_DIR/target/$TARGET_CODENAME/patches/china/vendor/etc/init/hw/"* "$WORK_DIR/vendor/etc/init/hw"
cp -a --preserve=all "$SRC_DIR/target/$TARGET_CODENAME/patches/china/vendor/firmware/"* "$WORK_DIR/odm/firmware"
SET_METADATA "odm" "firmware" 0 0 755 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/CAMERA_ICP.b20" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/CAMERA_ICP.mbn" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/CAMERA_ICP.mdt" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/a740_zap.b02" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/a740_zap.mbn" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/a740_zap.mdt" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/evass.b19" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/evass.mbn" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/evass.mdt" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "odm" "firmware/vpu30_4v.mbn" 0 0 644 "u:object_r:vendor_firmware_file:s0"
SET_METADATA "vendor" "etc/init/hw/init.samsung.firmware.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"

if ! grep -q "samsung.firmware" "$WORK_DIR/vendor/etc/init/hw/init.samsung.rc"; then
    sed -i "/samsung.connector/a import /vendor/etc/init/hw/init.samsung.firmware.rc" "$WORK_DIR/vendor/etc/init/hw/init.samsung.rc"
fi

if ! grep -q "vendor_firmware_file (file (mounton" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
    echo "(allow init_33_0 vendor_firmware_file (file (mounton)))" >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
fi
