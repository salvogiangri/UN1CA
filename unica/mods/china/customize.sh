DELETE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v5"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v6_DeviceSecurity"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.lool.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity_v6.xml"

ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/e1qzcx" "system" \
    "system/etc/permissions/privapp-permissions-com.samsung.android.applock.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/e1qzcx" "system" \
    "system/etc/permissions/privapp-permissions-com.samsung.android.sm_cn.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/e1qzcx" "system" \
    "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity.tcm_v6.xml" 0 0 644 "u:object_r:system_file:s0"
[ ! -f "$WORK_DIR/system/system/priv-app/SAppLock/SAppLock.apk" ] && \
    ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/e1qzcx" "system" "system/priv-app/AppLock" 0 0 755 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/e1qzcx" "system" "system/priv-app/SmartManagerCN" 0 0 755 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/e1qzcx" "system" "system/priv-app/SmartManager_v6_DeviceSecurity_CN" 0 0 755 "u:object_r:system_file:s0"

DOWNLOAD_FILE "$(GET_GALAXY_STORE_DOWNLOAD_URL "com.samsung.android.sm_cn")" \
    "$WORK_DIR/system/system/priv-app/SmartManagerCN/SmartManagerCN.apk"

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

SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME" "com.samsung.android.sm.devicesecurity.tcm"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME" "com.samsung.android.sm_cn"
