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
