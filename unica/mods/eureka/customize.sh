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
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

if [[ "$SOURCE_EXTRA_FIRMWARES" != "SM-S92"* ]]; then
    exit 1
fi

IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
MODEL=$(echo -n "${SOURCE_EXTRA_FIRMWARES[0]}" | cut -d "/" -f 1)
REGION=$(echo -n "${SOURCE_EXTRA_FIRMWARES[0]}" | cut -d "/" -f 2)

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/notifications"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ui"

cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/media/audio/"* "$WORK_DIR/system/system/media/audio"
cat "$FW_DIR/${MODEL}_${REGION}/fs_config-system" | grep -F "system/media/audio/" >> "$WORK_DIR/configs/fs_config-system"
cat "$FW_DIR/${MODEL}_${REGION}/file_context-system" | grep -F "system/media/audio/" >> "$WORK_DIR/configs/file_context-system"
ADD_TO_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sead.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.wallpaper.live.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/ringtones_count_list.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/hidden/INTERNAL_SDCARD/Music/Samsung/Over_the_Horizon.m4a" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/priv-app/EnvironmentAdaptiveDisplay/EnvironmentAdaptiveDisplay.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/priv-app/SpriteWallpaper/SpriteWallpaper.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/priv-app/wallpaper-res/wallpaper-res.apk" 0 0 644 "u:object_r:system_file:s0"

echo "- Processing \"Custom boot animation\" by @BlackMesa123"
bash "$SRC_DIR/unica/mods/bootanim/customize.sh"
