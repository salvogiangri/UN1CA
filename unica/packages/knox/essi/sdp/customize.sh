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
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/hidl_comm_ddar_client.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/hidl_comm_snap_client.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdualdar.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.tlc.ddar@1.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.tlc.snap@1.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/hidl_comm_ddar_client.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/hidl_comm_snap_client.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdualdar.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.tlc.ddar@1.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.tlc.snap@1.0.so"

if ! grep -q "sdp_cryptod" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/bin/sdp_cryptod u:object_r:sdp_cryptod_exec:s0"
        echo "/system/etc/init/sdp_cryptod\.rc u:object_r:system_file:s0"
        echo "/system/lib/libmdfpp_req\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libsdp_crypto\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libsdp_sdk\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libsdp_kekm\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libmdfpp_req\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libsdp_crypto\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libsdp_sdk\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libsdp_kekm\.so u:object_r:system_lib_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "sdp_cryptod" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/bin/sdp_cryptod 0 2000 755 capabilities=0x0"
        echo "system/etc/init/sdp_cryptod.rc 0 0 644 capabilities=0x0"
        echo "system/lib/libmdfpp_req.so 0 0 644 capabilities=0x0"
        echo "system/lib/libsdp_crypto.so 0 0 644 capabilities=0x0"
        echo "system/lib/libsdp_sdk.so 0 0 644 capabilities=0x0"
        echo "system/lib/libsdp_kekm.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libmdfpp_req.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libsdp_crypto.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libsdp_sdk.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libsdp_kekm.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
