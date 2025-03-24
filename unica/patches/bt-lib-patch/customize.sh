if [ ! -f "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" ]; then
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    unzip -q -j "$WORK_DIR/system/system/apex/com.android.btservices.apex" \
        "apex_payload.img" -d "$TMP_DIR"

    mkdir -p "$TMP_DIR/tmp_out"
    sudo mount -o ro "$TMP_DIR/apex_payload.img" "$TMP_DIR/tmp_out"
    sudo cat "$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so" > "$WORK_DIR/system/system/lib64/libbluetooth_jni.so"

    sudo umount "$TMP_DIR/tmp_out"
    rm -rf "$TMP_DIR"

    echo "/system/lib64/libbluetooth_jni\.so u:object_r:system_lib_file:s0" >> "$WORK_DIR/configs/file_context-system"
    echo "system/lib64/libbluetooth_jni.so 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
fi

# https://github.com/3arthur6/BluetoothLibraryPatcher/blob/425bb59da6505c962a38c143137698849b01d470/hexpatch.sh#L12
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "6804003528008052" "2b00001428008052"
