SKIPUNZIP=1

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

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

sed -i "s/SoundBooster_ver1100/SoundBooster_ver1050/g" "$WORK_DIR/configs/file_context-system"
sed -i "s/SoundBooster_ver1100/SoundBooster_ver1050/g" "$WORK_DIR/configs/fs_config-system"

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.keymint-V3-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.secureclock-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/lib_SoundBooster_ver1100.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/lib_SoundBooster_ver1100.so"
#REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhdcp_client_aidl.so"
#REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhdcp2.so"
#REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libremotedisplay_wfd.so"
#REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libremotedisplayservice.so"
#REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstagefright_hdcp.so"
#REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"

echo "Add stock blobs"
ADD_TO_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.adaptivebrightnessgo.cameralightsensor.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/sysconfig/preinstalled-packages-com.qualcomm.qti.services.secureui.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/priv-app/CameraLightSensor/CameraLightSensor.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/system_ext/app/com.qualcomm.qti.services.secureui/com.qualcomm.qti.services.secureui.apk" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock keymaster libs"
ADD_TO_WORK_DIR "system" "system/lib/android.hardware.keymaster@3.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/android.hardware.keymaster@4.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/android.hardware.keymaster@4.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/lib_nativeJni.dk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/libdk_native_keymaster.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/libkeymaster4_1support.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/libkeymaster4support.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/lib_nativeJni.dk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/libdk_native_keymaster.so" 0 0 644 "u:object_r:system_lib_file:s0"

echo "Add erofs disabled apex"
rm "$WORK_DIR/system/system/apex/com.samsung.android.shell.apex"
cp -a "$SRC_DIR/target/r8qxx/patches/stock_blobs/system/apex/com.samsung.android.shell.apex" "$WORK_DIR/system/system/apex"

echo "Add stock GameDriver"
ADD_TO_WORK_DIR "system" "system/priv-app/GameDriver-SM8250/GameDriver-SM8250.apk" 0 0 644 "u:object_r:system_file:s0"

#echo "Add stock WFD blobs"
#ADD_TO_WORK_DIR "system" "system/lib/libhdcp2.so" 0 0 644 "u:object_r:system_file:s0"
#ADD_TO_WORK_DIR "system" "system/lib/libremotedisplay_wfd.so" 0 0 644 "u:object_r:system_file:s0"
#ADD_TO_WORK_DIR "system" "system/lib/libremotedisplayservice.so" 0 0 644 "u:object_r:system_file:s0"
#ADD_TO_WORK_DIR "system" "system/lib/libsecuibc.so" 0 0 644 "u:object_r:system_file:s0" 
#ADD_TO_WORK_DIR "system" "system/lib/libstagefright_hdcp.so" 0 0 644 "u:object_r:system_file:s0"

echo "Fix Google Assistant"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/product/priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON" "$WORK_DIR/product/priv-app"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/product/priv-app/HotwordEnrollmentXGoogleEx3HEXAGON" "$WORK_DIR/product/priv-app"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON.apk.prof"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx3HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON.apk.prof"

# Fix later: Cannot find entry android.hardware.audio*.
#echo "Add stock vintf manifest"
#ADD_TO_WORK_DIR "system" "system/etc/vintf/compatibility_matrix.device.xml" 0 0 644 "u:object_r:system_file:s0"
#ADD_TO_WORK_DIR "system" "system/etc/vintf/manifest.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add /keyrefuge mount point"
mkdir -p "$WORK_DIR/system/keyrefuge"
echo "/keyrefuge u:object_r:keyrefuge_data_file:s0" >> "$WORK_DIR/configs/file_context-system"
echo "keyrefuge 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.clearcameraviewcover.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.flip.xml"
echo "Add stock system features"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.clearsideviewcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketmode_level33.xml" 0 0 644 "u:object_r:system_file:s0"
