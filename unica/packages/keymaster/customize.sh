SKIPUNZIP=1

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

if $SOURCE_HAS_KEYMINT; then
    if ! $TARGET_HAS_KEYMINT; then
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.keymint-V3-ndk.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.secureclock-V1-ndk.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdk_native_keymint.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.keymint-V2-ndk.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdk_native_keymint.so"
        cp -a --preserve=all "$SRC_DIR/unica/packages/keymaster/system/"* "$WORK_DIR/system/system"
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
    else
        echo "TARGET_HAS_KEYMINT is set. Ignoring"
    fi
else
    echo "SOURCE_HAS_KEYMINT is not set. Ignoring"
fi
