# [
ADD_TO_WORK_DIR()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    mkdir -p "$WORK_DIR/$(dirname "$FILE_PATH")"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$FILE_PATH" "$WORK_DIR/$FILE_PATH"

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

REMOVE_FROM_WORK_DIR "system" "system/lib/android.hardware.security.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib/android.hardware.security.secureclock-V1-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib/libcallaudio.so"
REMOVE_FROM_WORK_DIR "system" "system/lib/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/android.hardware.security.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/libcallaudio.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/libsecaudiomonomix.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.keymint-V2-ndk.so"
if ! grep -q "cameralightsensor" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.adaptivebrightnessgo\.cameralightsensor\.xml u:object_r:system_file:s0"
        echo "/system/etc/sysconfig/preinstalled-packages-com\.qualcomm\.qti\.services\.secureui\.xml u:object_r:system_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@3\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@4\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@4\.1\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libdk_native_keymaster\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libkeymaster4_1support\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libkeymaster4support\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libdk_native_keymaster\.so u:object_r:system_lib_file:s0"
        echo "/system/priv-app/CameraLightSensor u:object_r:system_file:s0"
        echo "/system/priv-app/CameraLightSensor/CameraLightSensor\.apk u:object_r:system_file:s0"
        echo "/system/system_ext/app/com\.qualcomm\.qti\.services\.secureui u:object_r:system_file:s0"
        echo "/system/system_ext/app/com\.qualcomm\.qti\.services\.secureui/com\.qualcomm\.qti\.services\.secureui\.apk u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "cameralightsensor" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/etc/permissions/privapp-permissions-com.samsung.adaptivebrightnessgo.cameralightsensor.xml 0 0 644 capabilities=0x0"
        echo "system/etc/sysconfig/preinstalled-packages-com.qualcomm.qti.services.secureui.xml 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@3.0.so 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@4.0.so 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@4.1.so 0 0 644 capabilities=0x0"
        echo "system/lib/libdk_native_keymaster.so 0 0 644 capabilities=0x0"
        echo "system/lib/libkeymaster4_1support.so 0 0 644 capabilities=0x0"
        echo "system/lib/libkeymaster4support.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libdk_native_keymaster.so 0 0 644 capabilities=0x0"
        echo "system/priv-app/CameraLightSensor 0 0 755 capabilities=0x0"
        echo "system/priv-app/CameraLightSensor/CameraLightSensor.apk 0 0 644 capabilities=0x0"
        echo "system/system_ext/app/com.qualcomm.qti.services.secureui 0 0 755 capabilities=0x0"
        echo "system/system_ext/app/com.qualcomm.qti.services.secureui/com.qualcomm.qti.services.secureui.apk 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi

echo "Fix Google Assistant"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"

echo "Add stock rscmgr.rc"
ADD_TO_WORK_DIR "system" "system/etc/init/rscmgr.rc" 0 0 644 "u:object_r:system_file:s0"

REMOVE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.clearcameraviewcover.xml"
REMOVE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.flip.xml"
REMOVE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketsensitivitymode_level1.xml"
echo "Add stock system features"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.clearsideviewcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketmode_level33.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock ev_lux_map_config.xml"
ADD_TO_WORK_DIR "system" "system/etc/ev_lux_map_config.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock GameDriver"
ADD_TO_WORK_DIR "system" "system/priv-app/GameDriver-SM8250/GameDriver-SM8250.apk" 0 0 644 "u:object_r:system_file:s0"
