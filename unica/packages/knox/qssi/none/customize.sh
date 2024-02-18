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

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/bin/dualdard"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/init/dualdard.rc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdualdar.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libepm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libkeyutils.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libknox_filemanager.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libpersona.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdualdar.so"
