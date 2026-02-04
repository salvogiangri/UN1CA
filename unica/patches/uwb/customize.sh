SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

SOURCE_HAS_UWB="$(test -f "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.uwb.xml" && echo "true" || echo "false")"
TARGET_HAS_UWB="$(test -f "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.uwb.xml" && echo "true" || echo "false")"

if ! $SOURCE_HAS_UWB; then
    if $TARGET_HAS_UWB; then
        if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "mssi" ]]; then
            ABORT "\"mssi\" system image does not support targets with UWB. Aborting"
        fi

        LOG "- Adding \"ro.boot.uwbcountrycode\" prop with \"ff\" in /product/etc/build.prop"
        EVAL "sed -i \"/usb.config/a ro.boot.uwbcountrycode=ff\" \"$WORK_DIR/product/etc/build.prop\""

        ADD_TO_WORK_DIR "b0qxxx" "product" \
            "overlay/UwbRROverlay.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/app/UwbTest/UwbTest.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "b0qxxx" || echo "b0sxxx")" \
            "system" "system/etc/classpaths/bootclasspath.pb" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/init/init.system.uwb.rc" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/com.samsung.android.uwb_extras.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/org.carconnectivity.android.digitalkey.timesync.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/privapp-permissions-com.samsung.android.dcktimesync.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/privapp-permissions-com.sec.android.app.uwbtest.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/libuwb-cal.conf" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/pp_model.tflite" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/framework/com.samsung.android.uwb_extras.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/framework/semuwb-service.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/lib/libtflite_uwb_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/lib64/libtflite_uwb_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system_ext" \
            "framework/org.carconnectivity.android.digitalkey.timesync.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system_ext" \
            "priv-app/DckTimeSyncService/DckTimeSyncService.apk" 0 0 644 "u:object_r:system_file:s0"
    else
        LOG "\033[0;33m! Nothing to do\033[0m"
    fi
else
    if ! $TARGET_HAS_UWB; then
        ABORT "Missing patch for condition (SOURCE_HAS_UWB: [$SOURCE_HAS_UWB], TARGET_HAS_UWB: [$TARGET_HAS_UWB]). Aborting"
    fi
fi

unset SOURCE_FIRMWARE_PATH TARGET_FIRMWARE_PATH SOURCE_HAS_UWB TARGET_HAS_UWB
