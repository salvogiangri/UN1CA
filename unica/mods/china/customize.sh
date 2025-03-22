SET_CONFIG()
{
    local CONFIG="$1"
    local VALUE="$2"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        CONFIG="$(echo -n "$CONFIG" | sed 's/=//g')"
        if grep -Fq "$CONFIG" "$FILE"; then
            echo "Deleting \"$CONFIG\" config in /system/system/etc/floating_feature.xml"
            sed -i "/$CONFIG/d" "$FILE"
        fi
    else
        if grep -Fq "<$CONFIG>" "$FILE"; then
            echo "Replacing \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
            sed -i "$(sed -n "/<${CONFIG}>/=" "$FILE") c\ \ \ \ <${CONFIG}>${VALUE}</${CONFIG}>" "$FILE"
        else
            echo "Adding \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
            sed -i "/<\/SecFloatingFeatureSet>/d" "$FILE"
            if ! grep -q "Added by unica" "$FILE"; then
                echo "    <!-- Added by unica/patches/floating_feature/customize.sh -->" >> "$FILE"
            fi
            echo "    <${CONFIG}>${VALUE}</${CONFIG}>" >> "$FILE"
            echo "</SecFloatingFeatureSet>" >> "$FILE"
        fi
    fi
}

[ -f "$WORK_DIR/system/system/priv-app/AppLock/AppLock.apk" ] \
    && mv -f "$WORK_DIR/system/system/priv-app/AppLock/AppLock.apk" "$WORK_DIR/system/system/priv-app/AppLock/SAppLock.apk"
[ -d "$WORK_DIR/system/system/priv-app/AppLock" ] \
    && mv -f "$WORK_DIR/system/system/priv-app/AppLock" "$WORK_DIR/system/system/priv-app/SAppLock"

REMOVE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v5"
REMOVE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v6_DeviceSecurity"
REMOVE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.lool.xml"
REMOVE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity_v6.xml"

SET_CONFIG "SEC_FLOATING_FEATURE_SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME" "com.samsung.android.sm.devicesecurity.tcm"
SET_CONFIG "SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME" "com.samsung.android.sm_cn"

if ! grep -q "SmartManagerCN" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.applock\.xml u:object_r:system_file:s0"
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.sm\.devicesecurity\.tcm_v6\.xml u:object_r:system_file:s0"
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.sm_cn\.xml u:object_r:system_file:s0"
        echo "/system/priv-app/SAppLock u:object_r:system_file:s0"
        echo "/system/priv-app/SAppLock/SAppLock\.apk u:object_r:system_file:s0"
        echo "/system/priv-app/SmartManagerCN u:object_r:system_file:s0"
        echo "/system/priv-app/SmartManagerCN/SmartManagerCN\.apk u:object_r:system_file:s0"
        echo "/system/priv-app/SmartManager_v6_DeviceSecurity_CN u:object_r:system_file:s0"
        echo "/system/priv-app/SmartManager_v6_DeviceSecurity_CN/SmartManager_v6_DeviceSecurity_CN\.apk u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "SmartManagerCN" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/etc/permissions/privapp-permissions-com.samsung.android.applock.xml 0 0 644 capabilities=0x0"
        echo "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity.tcm_v6.xml 0 0 644 capabilities=0x0"
        echo "system/etc/permissions/privapp-permissions-com.samsung.android.sm_cn.xml 0 0 644 capabilities=0x0"
        echo "system/priv-app/SAppLock 0 0 755 capabilities=0x0"
        echo "system/priv-app/SAppLock/SAppLock.apk 0 0 644 capabilities=0x0"
        echo "system/priv-app/SmartManagerCN 0 0 755 capabilities=0x0"
        echo "system/priv-app/SmartManagerCN/SmartManagerCN.apk 0 0 644 capabilities=0x0"
        echo "system/priv-app/SmartManager_v6_DeviceSecurity_CN 0 0 755 capabilities=0x0"
        echo "system/priv-app/SmartManager_v6_DeviceSecurity_CN/SmartManager_v6_DeviceSecurity_CN.apk 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
