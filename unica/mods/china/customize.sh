LOG_STEP_IN "- Removing Device Care & AppLock"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.lool.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity_v6.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/signature-permissions-com.samsung.android.lool.xml"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v5"
DELETE_FROM_WORK_DIR "system" "system/app/SmartManager_v6_DeviceSecurity"
LOG_STEP_OUT 

LOG_STEP_IN "- Installing @saadelasfur's China mods"
CURL_AUTH_ARGS=${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"}
GITHUB_API="https://api.github.com/repos/saadelasfur/SmartManager/releases/latest"
CN_APPS=$(curl -s $CURL_AUTH_ARGS "$GITHUB_API" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p' | grep -i 'SmartManagerCN-OneUI.*\.zip' | head -n1)
ZIP_FILENAME=$(basename "$CN_APPS")

DOWNLOAD_FILE "$CN_APPS" "$MODPATH/$ZIP_FILENAME"
unzip -o "$MODPATH/$ZIP_FILENAME" 'packages/*' -d "$MODPATH"
mv "$MODPATH/packages" "$MODPATH/system"

ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 2000 755 "u:object_r:system_file:s0"

rm -rf "$MODPATH/system"
rm -f "$MODPATH/$ZIP_FILENAME"
LOG_STEP_OUT

LOG_STEP_IN "- Patching floating_feature.xml"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME" "com.samsung.android.sm_cn"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME" "com.samsung.android.sm.devicesecurity"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_NAL_PRELOADAPP_REGULATION" "TRUE"
LOG_STEP_OUT

unset CURL_AUTH_ARGS GITHUB_API CN_APPS ZIP_FILENAME