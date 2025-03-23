SKIPUNZIP=1

SOURCE_FIRMWARE_PATH="$FW_DIR/$(echo -n "$SOURCE_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"
TARGET_FIRMWARE_PATH="$FW_DIR/$(echo -n "$TARGET_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"

if [ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libuwb-cal.conf" ]; then
    if ! grep -q "uwbcountrycode" "$WORK_DIR/product/etc/build.prop"; then
        sed -i "/usb.config/a ro.boot.uwbcountrycode=ff" "$WORK_DIR/product/etc/build.prop"
    fi

    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libuwb-cal.conf" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/pp_model.tflite" 0 0 644 "u:object_r:system_file:s0"

    if [ ! -d "$SOURCE_FIRMWARE_PATH/system/system/app/UwbUci" ]; then
        cp -a --preserve=all "$SRC_DIR/unica/patches/uwb/system/"* "$WORK_DIR/system/system"
        if ! grep -q "UwbUci" "$WORK_DIR/configs/file_context-system"; then
            {
                echo "/system/app/UwbUci u:object_r:system_file:s0"
                echo "/system/app/UwbUci/UwbUci\.apk u:object_r:system_file:s0"
                echo "/system/etc/init/init\.system\.uwb\.rc u:object_r:system_file:s0"
                echo "/system/etc/permissions/com\.samsung\.android\.uwb_extras\.xml u:object_r:system_file:s0"
                echo "/system/etc/permissions/org\.carconnectivity\.android\.digitalkey\.timesync\.xml u:object_r:system_file:s0"
                echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.dcktimesync\.xml u:object_r:system_file:s0"
                echo "/system/etc/permissions/samsung\.uwb\.xml u:object_r:system_file:s0"
                echo "/system/framework/com\.samsung\.android\.uwb_extras\.jar u:object_r:system_file:s0"
                echo "/system/framework/samsung\.uwb\.jar u:object_r:system_file:s0"
                echo "/system/lib/libtflite_uwb_jni\.so u:object_r:system_lib_file:s0"
                echo "/system/lib/libuwb_uci_jni_rust\.so u:object_r:system_lib_file:s0"
                echo "/system/lib64/libtflite_uwb_jni\.so u:object_r:system_lib_file:s0"
                echo "/system/lib64/libuwb_uci_jni_rust\.so u:object_r:system_lib_file:s0"
            } >> "$WORK_DIR/configs/file_context-system"
        fi
        if ! grep -q "UwbUci" "$WORK_DIR/configs/fs_config-system"; then
            {
                echo "system/app/UwbUci 0 0 755 capabilities=0x0"
                echo "system/app/UwbUci/UwbUci.apk 0 0 644 capabilities=0x0"
                echo "system/etc/init/init.system.uwb.rc 0 0 644 capabilities=0x0"
                echo "system/etc/permissions/com.samsung.android.uwb_extras.xml 0 0 644 capabilities=0x0"
                echo "system/etc/permissions/org.carconnectivity.android.digitalkey.timesync.xml 0 0 644 capabilities=0x0"
                echo "system/etc/permissions/privapp-permissions-com.samsung.android.dcktimesync.xml 0 0 644 capabilities=0x0"
                echo "system/etc/permissions/samsung.uwb.xml 0 0 644 capabilities=0x0"
                echo "system/framework/com.samsung.android.uwb_extras.jar 0 0 644 capabilities=0x0"
                echo "system/framework/samsung.uwb.jar 0 0 644 capabilities=0x0"
                echo "system/lib/libtflite_uwb_jni.so 0 0 644 capabilities=0x0"
                echo "system/lib/libuwb_uci_jni_rust.so 0 0 644 capabilities=0x0"
                echo "system/lib64/libtflite_uwb_jni.so 0 0 644 capabilities=0x0"
                echo "system/lib64/libuwb_uci_jni_rust.so 0 0 644 capabilities=0x0"
            } >> "$WORK_DIR/configs/fs_config-system"
        fi

        if $TARGET_HAS_SYSTEM_EXT; then
            cp -a --preserve=all "$SRC_DIR/unica/patches/uwb/system_ext/"* "$WORK_DIR/system_ext"
            if ! grep -q "DckTimeSyncService" "$WORK_DIR/configs/file_context-system_ext"; then
                {
                    echo "/system_ext/framework/org\.carconnectivity\.android\.digitalkey\.timesync\.jar u:object_r:system_file:s0"
                    echo "/system_ext/priv-app/DckTimeSyncService u:object_r:system_file:s0"
                    echo "/system_ext/priv-app/DckTimeSyncService/DckTimeSyncService\.apk u:object_r:system_file:s0"
                } >> "$WORK_DIR/configs/file_context-system_ext"
            fi
            if ! grep -q "DckTimeSyncService" "$WORK_DIR/configs/fs_config-system_ext"; then
                {
                    echo "system_ext/framework/org.carconnectivity.android.digitalkey.timesync.jar 0 0 644 capabilities=0x0"
                    echo "system_ext/priv-app/DckTimeSyncService 0 0 755 capabilities=0x0"
                    echo "system_ext/priv-app/DckTimeSyncService/DckTimeSyncService.apk 0 0 644 capabilities=0x0"
                } >> "$WORK_DIR/configs/fs_config-system_ext"
            fi
        else
            cp -a --preserve=all "$SRC_DIR/unica/patches/uwb/system_ext/"* "$WORK_DIR/system/system/system_ext"
            if ! grep -q "DckTimeSyncService" "$WORK_DIR/configs/file_context-system"; then
                {
                    echo "/system/system_ext/framework/org\.carconnectivity\.android\.digitalkey\.timesync\.jar u:object_r:system_file:s0"
                    echo "/system/system_ext/priv-app/DckTimeSyncService u:object_r:system_file:s0"
                    echo "/system/system_ext/priv-app/DckTimeSyncService/DckTimeSyncService\.apk u:object_r:system_file:s0"
                } >> "$WORK_DIR/configs/file_context-system"
            fi
            if ! grep -q "DckTimeSyncService" "$WORK_DIR/configs/fs_config-system"; then
                {
                    echo "system/system_ext/framework/org.carconnectivity.android.digitalkey.timesync.jar 0 0 644 capabilities=0x0"
                    echo "system/system_ext/priv-app/DckTimeSyncService 0 0 755 capabilities=0x0"
                    echo "system/system_ext/priv-app/DckTimeSyncService/DckTimeSyncService.apk 0 0 644 capabilities=0x0"
                } >> "$WORK_DIR/configs/fs_config-system"
            fi
        fi
    fi
fi
