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
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Add stock vintf manifest"
ADD_TO_WORK_DIR "system" "system/etc/vintf/compatibility_matrix.device.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/vintf/manifest.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock rscmgr.rc"
ADD_TO_WORK_DIR "system" "system/etc/init/rscmgr.rc" 0 0 644 "u:object_r:system_file:s0"

REMOVE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketsensitivitymode_level1.xml"
echo "Add stock system features"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.nfcledcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketmode_level33.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.spen_usp_level60.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock GameDriver"
ADD_TO_WORK_DIR "system" "system/priv-app/GameDriver-SM8450/GameDriver-SM8450.apk" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock WFD blobs"
ADD_TO_WORK_DIR "system" "system/lib64/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"

echo "Add stock libhwui"
ADD_TO_WORK_DIR "system" "system/lib/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"

REMOVE_FROM_WORK_DIR "system" "system/lib/android.hardware.security.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/android.hardware.security.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.keymint-V2-ndk.so"
echo "Add stock keymint libs"
ADD_TO_WORK_DIR "system" "system/lib/android.hardware.security.keymint-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/libdk_native_keymint.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib/vendor.samsung.hardware.keymint-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/libdk_native_keymint.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.keymint-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
