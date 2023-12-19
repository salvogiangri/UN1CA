REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

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

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.clearcameraviewcover.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.flip.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.sensorhub_level29.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.wirelesscharger_authentication.xml"
echo "Add stock system features"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/permissions/com.sec.feature.cover.minisviewwalletcover.xml" \
    "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.minisviewwalletcover.xml"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/permissions/com.sec.feature.sensorhub_level40.xml" \
    "$WORK_DIR/system/system/etc/permissions/com.sec.feature.sensorhub_level40.xml"
if ! grep -q "minisviewwalletcover" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/etc/permissions/com\.sec\.feature\.cover\.minisviewwalletcover\.xml u:object_r:system_file:s0"
        echo "/system/etc/permissions/com\.sec\.feature\.sensorhub_level40\.xml u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "minisviewwalletcover" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/etc/permissions/com.sec.feature.cover.minisviewwalletcover.xml 0 0 644 capabilities=0x0"
        echo "system/etc/permissions/com.sec.feature.sensorhub_level40.xml 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
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

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.keymint-V3-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.secureclock-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdk_native_keymint.so"
if ! grep -q "libdk_native_keymaster" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/lib/android\.hardware\.keymaster@3\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@4\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@4\.1\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libdk_native_keymaster\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libkeymaster4_1support\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libkeymaster4support\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libdk_native_keymaster\.so u:object_r:system_lib_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "libdk_native_keymaster" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/lib/android.hardware.keymaster@3.0.so 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@4.0.so 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@4.1.so 0 0 644 capabilities=0x0"
        echo "system/lib/libdk_native_keymaster.so 0 0 644 capabilities=0x0"
        echo "system/lib/libkeymaster4_1support.so 0 0 644 capabilities=0x0"
        echo "system/lib/libkeymaster4support.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libdk_native_keymaster.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
