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

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

if ! $SOURCE_HAS_MASS_CAMERA_APP; then
    if $TARGET_HAS_MASS_CAMERA_APP; then
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/SamsungCamera/oat"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/SamsungCamera/SamsungCamera.apk.prof"
        cp -a --preserve=all "$SRC_DIR/unica/packages/mass_cam/system/"* "$WORK_DIR/system/system"
        if ! grep -q "FunModeSDK" "$WORK_DIR/configs/file_context-system"; then
            {
                echo "/system/app/FunModeSDK u:object_r:system_file:s0"
                echo "/system/app/FunModeSDK/FunModeSDK\.apk u:object_r:system_file:s0"
            } >> "$WORK_DIR/configs/file_context-system"
        fi
        if ! grep -q "FunModeSDK" "$WORK_DIR/configs/fs_config-system"; then
            {
                echo "system/app/FunModeSDK 0 0 755 capabilities=0x0"
                echo "system/app/FunModeSDK/FunModeSDK.apk 0 0 644 capabilities=0x0"
            } >> "$WORK_DIR/configs/fs_config-system"
        fi
    else
        echo "TARGET_HAS_MASS_CAMERA_APP is not set. Ignoring"
    fi
else
    echo "SOURCE_HAS_MASS_CAMERA_APP is set. Ignoring"
fi
