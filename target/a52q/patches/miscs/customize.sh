MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Add stock /vendor/ueventd.rc"
if [ ! -f "$WORK_DIR/vendor/ueventd.rc" ]; then
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/vendor/ueventd.rc" "$WORK_DIR/vendor/ueventd.rc"
    echo "/vendor/ueventd\.rc u:object_r:vendor_file:s0" >> "$WORK_DIR/configs/file_context-odm"
    echo "vendor/ueventd.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/product/etc/build.prop"

echo "Add HIDL fingerprint biometrics libs"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/android.hardware.biometrics.fingerprint@2.1.so" \
    "$WORK_DIR/system/system/lib"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/vendor.samsung.hardware.biometrics.fingerprint@3.0.so" \
    "$WORK_DIR/system/system/lib"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/android.hardware.biometrics.fingerprint@2.1.so" \
    "$WORK_DIR/system/system/lib64"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/vendor.samsung.hardware.biometrics.fingerprint@3.0.so" \
    "$WORK_DIR/system/system/lib64"
{
    echo "/system/lib/android\.hardware\.biometrics\.fingerprint@2\.1\.so u:object_r:system_lib_file:s0"
    echo "/system/lib/vendor\.samsung\.hardware\.biometrics\.fingerprint@3\.0\.so u:object_r:system_lib_file:s0"
    echo "/system/lib64/android\.hardware\.biometrics\.fingerprint@2\.1\.so u:object_r:system_lib_file:s0"
    echo "/system/lib64/vendor\.samsung\.hardware\.biometrics\.fingerprint@3\.0\.so u:object_r:system_lib_file:s0"
} >> "$WORK_DIR/configs/file_context-system"
{
    echo "system/lib/android.hardware.biometrics.fingerprint@2.1.so 0 0 644 capabilities=0x0"
    echo "system/lib/vendor.samsung.hardware.biometrics.fingerprint@3.0.so 0 0 644 capabilities=0x0"
    echo "system/lib64/android.hardware.biometrics.fingerprint@2.1.so 0 0 644 capabilities=0x0"
    echo "system/lib64/vendor.samsung.hardware.biometrics.fingerprint@3.0.so 0 0 644 capabilities=0x0"
} >> "$WORK_DIR/configs/fs_config-system"
