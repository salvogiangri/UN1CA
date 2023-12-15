echo "Fix Google Assistant"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"

echo "Add stock /odm/ueventd.rc"
if [ ! -f "$WORK_DIR/odm/ueventd.rc" ]; then
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/odm/ueventd.rc" "$WORK_DIR/odm/ueventd.rc"
    echo "/odm/ueventd\.rc u:object_r:vendor_file:s0" >> "$WORK_DIR/configs/file_context-odm"
    echo "odm/ueventd.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Add HIDL fingerprint biometrics libs"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/android.hardware.biometrics.fingerprint@2.1.so" \
    "$WORK_DIR/system/system/lib"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/vendor.samsung.hardware.biometrics.fingerprint@3.0.so" \
    "$WORK_DIR/system/system/lib"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/android.hardware.biometrics.fingerprint@2.1.so" \
    "$WORK_DIR/system/system/lib64"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/vendor.samsung.hardware.biometrics.fingerprint@3.0.so" \
    "$WORK_DIR/system/system/lib64"
if ! grep -q "fingerprint@3\.0\.so" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/lib/android\.hardware\.biometrics\.fingerprint@2\.1\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/vendor\.samsung\.hardware\.biometrics\.fingerprint@3\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/android\.hardware\.biometrics\.fingerprint@2\.1\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/vendor\.samsung\.hardware\.biometrics\.fingerprint@3\.0\.so u:object_r:system_lib_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "fingerprint@3.0.so" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/lib/android.hardware.biometrics.fingerprint@2.1.so 0 0 644 capabilities=0x0"
        echo "system/lib/vendor.samsung.hardware.biometrics.fingerprint@3.0.so 0 0 644 capabilities=0x0"
        echo "system/lib64/android.hardware.biometrics.fingerprint@2.1.so 0 0 644 capabilities=0x0"
        echo "system/lib64/vendor.samsung.hardware.biometrics.fingerprint@3.0.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
