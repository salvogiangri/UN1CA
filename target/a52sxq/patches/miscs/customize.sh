SKIPUNZIP=1

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Add stock /odm/ueventd.rc"
if [ ! -f "$WORK_DIR/odm/ueventd.rc" ]; then
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/odm/ueventd.rc" "$WORK_DIR/odm/ueventd.rc"
    echo "/odm/ueventd\.rc u:object_r:vendor_file:s0" >> "$WORK_DIR/configs/file_context-odm"
    echo "odm/ueventd.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/product/etc/build.prop"

echo "Add stock vintf manifest"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/vintf/compatibility_matrix.device.xml" \
    "$WORK_DIR/system/system/etc/vintf/compatibility_matrix.device.xml"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/vintf/manifest.xml" \
    "$WORK_DIR/system/system/etc/vintf/manifest.xml"

echo "Add HIDL face biometrics libs"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/system_ext/lib/vendor.samsung.hardware.biometrics.face@3.0.so" \
    "$WORK_DIR/system/system/system_ext/lib"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/system_ext/lib64/vendor.samsung.hardware.biometrics.face@3.0.so" \
    "$WORK_DIR/system/system/system_ext/lib64"
{
    echo "/system/system_ext/lib/vendor\.samsung\.hardware\.biometrics\.face@3\.0\.so u:object_r:system_lib_file:s0"
    echo "/system/system_ext/lib64/vendor\.samsung\.hardware\.biometrics\.face@3\.0\.so u:object_r:system_lib_file:s0"
} >> "$WORK_DIR/configs/file_context-system"
{
    echo "system/system_ext/lib/vendor.samsung.hardware.biometrics.face@3.0.so 0 0 644 capabilities=0x0"
    echo "system/system_ext/lib64/vendor.samsung.hardware.biometrics.face@3.0.so 0 0 644 capabilities=0x0"
} >> "$WORK_DIR/configs/fs_config-system"
