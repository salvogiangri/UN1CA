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

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/privapp-permissions-com.samsung.android.kgclient.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/public.libraries-wsm.samsung.txt"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libhal.wsm.samsung.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhal.wsm.samsung.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/KnoxGuard"
