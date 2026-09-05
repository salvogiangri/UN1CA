SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

SOURCE_HAS_CLOCKPACK="$(test -n "$(find "$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/priv-app" -type d -name "ClockPack*")" && echo "true" || echo "false")"
TARGET_HAS_CLOCKPACK="$(test -n "$(find "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/priv-app" -type d -name "ClockPack*")" && echo "true" || echo "false")"

if ! $SOURCE_HAS_CLOCKPACK; then
    if $TARGET_HAS_CLOCKPACK; then
        DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.samsung.feature.aodservice_v10.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.aodservice.xml"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/AODService_v80"

        ADD_TO_WORK_DIR "a17xxx" "system" "system/etc/permissions/com.samsung.feature.clockpack_v10.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "a17xxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.clockpack.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "a17xxx" "system" "system/priv-app/ClockPack_v80" 0 0 755 "u:object_r:system_file:s0"

        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_AOD_ITEM" --delete
    else
        LOG "\033[0;33m! Nothing to do\033[0m"
    fi
else
    if ! $TARGET_HAS_CLOCKPACK; then
        ABORT "Missing patch for condition (SOURCE_HAS_CLOCKPACK: [$SOURCE_HAS_CLOCKPACK], TARGET_HAS_CLOCKPACK: [$TARGET_HAS_CLOCKPACK]). Aborting"
    fi
fi

unset SOURCE_FIRMWARE_PATH TARGET_FIRMWARE_PATH SOURCE_HAS_CLOCKPACK TARGET_HAS_CLOCKPACK
