if ! $SOURCE_HAS_MASS_CAMERA_APP; then
    if $TARGET_HAS_MASS_CAMERA_APP; then
        if [[ -d "$WORK_DIR/system/system/priv-app/SamsungCamera/oat" ]]; then
            DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/oat"
        fi
        if [[ -f "$WORK_DIR/system/system/priv-app/SamsungCamera/SamsungCamera.apk.prof" ]]; then
            DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/SamsungCamera.apk.prof"
        fi
        ADD_TO_WORK_DIR "a73xqxx" "system" "system/app/FunModeSDK/FunModeSDK.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "r11sxxx" "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" 0 0 644 "u:object_r:system_file:s0"
    else
        echo "TARGET_HAS_MASS_CAMERA_APP is not set. Ignoring"
    fi
else
    echo "SOURCE_HAS_MASS_CAMERA_APP is set. Ignoring"
fi
