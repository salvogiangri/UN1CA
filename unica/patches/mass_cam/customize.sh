if ! $SOURCE_HAS_MASS_CAMERA_APP; then
    if $TARGET_HAS_MASS_CAMERA_APP; then
        DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/oat"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/SamsungCamera.apk.prof"
        ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/a73xqxx" "system" "system/app/FunModeSDK/FunModeSDK.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/r11sxxx" "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" 0 0 644 "u:object_r:system_file:s0"
    else
        echo "TARGET_HAS_MASS_CAMERA_APP is not set. Ignoring"
    fi
else
    echo "SOURCE_HAS_MASS_CAMERA_APP is set. Ignoring"
fi
