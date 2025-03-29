SOURCE_FIRMWARE_PATH="$FW_DIR/$(echo -n "$SOURCE_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"
TARGET_FIRMWARE_PATH="$FW_DIR/$(echo -n "$TARGET_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"

if [ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libuwb-cal.conf" ]; then
    if ! grep -q "uwbcountrycode" "$WORK_DIR/product/etc/build.prop"; then
        sed -i "/usb.config/a ro.boot.uwbcountrycode=ff" "$WORK_DIR/product/etc/build.prop"
    fi

    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libuwb-cal.conf" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/pp_model.tflite" 0 0 644 "u:object_r:system_file:s0"

    if [ ! -d "$SOURCE_FIRMWARE_PATH/system/system/app/UwbUci" ]; then
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/app/UwbUci/UwbUci.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/etc/init/init.system.uwb.rc" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/etc/permissions/com.samsung.android.uwb_extras.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/etc/permissions/org.carconnectivity.android.digitalkey.timesync.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/etc/permissions/privapp-permissions-com.samsung.android.dcktimesync.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/etc/permissions/samsung.uwb.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/framework/com.samsung.android.uwb_extras.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/framework/samsung.uwb.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/lib/libtflite_uwb_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/lib/libuwb_uci_jni_rust.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/lib64/libtflite_uwb_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system" \
            "system/lib64/libuwb_uci_jni_rust.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system_ext" \
            "framework/org.carconnectivity.android.digitalkey.timesync.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "dm3qxxx" "system_ext" \
            "priv-app/DckTimeSyncService/DckTimeSyncService.apk" 0 0 644 "u:object_r:system_file:s0"
    fi
fi
