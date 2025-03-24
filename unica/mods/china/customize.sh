if [ -f "$WORK_DIR/system/system/priv-app/AppLock/AppLock.apk" ]; then
    mv -f "$WORK_DIR/system/system/priv-app/AppLock/AppLock.apk" "$WORK_DIR/system/system/priv-app/AppLock/SAppLock.apk"
    sed -i "s/AppLock.apk/SAppLock.apk/g" "$WORK_DIR/configs/fs_config-system"
    sed -i "s/AppLock\\\.apk/SAppLock\\\.apk/g" "$WORK_DIR/configs/file_context-system"
fi
if [ -d "$WORK_DIR/system/system/priv-app/AppLock" ]; then
    mv -f "$WORK_DIR/system/system/priv-app/AppLock" "$WORK_DIR/system/system/priv-app/SAppLock"
    sed -i "s/priv-app\/AppLock/priv-app\/SAppLock/g" "$WORK_DIR/configs/fs_config-system"
    sed -i "s/priv-app\/AppLock/priv-app\/SAppLock/g" "$WORK_DIR/configs/file_context-system"
fi

DELETE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v5"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v6_DeviceSecurity/"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.lool.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity_v6.xml"

SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME" "com.samsung.android.sm.devicesecurity.tcm"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME" "com.samsung.android.sm_cn"
