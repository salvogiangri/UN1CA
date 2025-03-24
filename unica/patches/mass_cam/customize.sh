SKIPUNZIP=1

if ! $SOURCE_HAS_MASS_CAMERA_APP; then
    if $TARGET_HAS_MASS_CAMERA_APP; then
        DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/oat"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/SamsungCamera.apk.prof"
        ADD_TO_WORK_DIR "$SRC_DIR/unica/patches/mass_cam" "system" "." 0 0 755 "u:object_r:system_file:s0"
    else
        echo "TARGET_HAS_MASS_CAMERA_APP is not set. Ignoring"
    fi
else
    echo "SOURCE_HAS_MASS_CAMERA_APP is set. Ignoring"
fi
