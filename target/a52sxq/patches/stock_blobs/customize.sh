SKIPUNZIP=1

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Add stock /odm/ueventd.rc"
if [ ! -f "$WORK_DIR/odm/ueventd.rc" ]; then
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/odm/ueventd.rc" "$WORK_DIR/odm/ueventd.rc"
    echo "/odm/ueventd\.rc u:object_r:vendor_file:s0" >> "$WORK_DIR/configs/file_context-odm"
    echo "odm/ueventd.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Fix Google Assistant"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/product/priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON" "$WORK_DIR/product/priv-app"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/product/priv-app/HotwordEnrollmentXGoogleEx3HEXAGON" "$WORK_DIR/product/priv-app"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"

echo "Add stock vintf manifest"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/vintf/compatibility_matrix.device.xml" \
    "$WORK_DIR/system/system/etc/vintf/compatibility_matrix.device.xml"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/vintf/manifest.xml" \
    "$WORK_DIR/system/system/etc/vintf/manifest.xml"

echo "Add stock Tlc libs"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/libtlc_blockchain_keystore.so" \
    "$WORK_DIR/system/system/lib/libtlc_blockchain_keystore.so"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/libtlc_payment_spay.so" \
    "$WORK_DIR/system/system/lib/libtlc_payment_spay.so"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/libtlc_blockchain_keystore.so" \
    "$WORK_DIR/system/system/lib64/libtlc_blockchain_keystore.so"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/libtlc_payment_spay.so" \
    "$WORK_DIR/system/system/lib64/libtlc_payment_spay.so"

echo "Add HIDL face biometrics libs"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/system_ext/lib/vendor.samsung.hardware.biometrics.face@3.0.so" \
    "$WORK_DIR/system/system/system_ext/lib"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/system_ext/lib64/vendor.samsung.hardware.biometrics.face@3.0.so" \
    "$WORK_DIR/system/system/system_ext/lib64"
if ! grep -q "face@3\.0\.so" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/system_ext/lib/vendor\.samsung\.hardware\.biometrics\.face@3\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib64/vendor\.samsung\.hardware\.biometrics\.face@3\.0\.so u:object_r:system_lib_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "face@3.0.so" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/system_ext/lib/vendor.samsung.hardware.biometrics.face@3.0.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib64/vendor.samsung.hardware.biometrics.face@3.0.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
