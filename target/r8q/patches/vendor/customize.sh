REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".camera.samsung.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
        fi
        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".arcsoft.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt"
        fi

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhdcp_client_aidl.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhdcp2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libremotedisplay_wfd.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libremotedisplayservice.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstagefright_hdcp.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"

if ! grep -q "remotedisplay_wfd" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/lib/libhdcp2\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libremotedisplay_wfd\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libremotedisplayservice\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libsecuibc\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libstagefright_hdcp\.so u:object_r:system_lib_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "remotedisplay_wfd" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/lib/libhdcp2.so 0 0 644 capabilities=0x0"
        echo "system/lib/libremotedisplay_wfd.so 0 0 644 capabilities=0x0"
        echo "system/lib/libremotedisplayservice.so 0 0 644 capabilities=0x0"
        echo "system/lib/libsecuibc.so 0 0 644 capabilities=0x0"
        echo "system/lib/libstagefright_hdcp.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi

REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.vibrator@2.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.vibrator@2.1.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.vibrator@2.2.so"

if ! grep -q "vibrator-default" "$WORK_DIR/configs/file_context-vendor"; then
    {
        echo "/vendor/bin/hw/vendor\.samsung\.hardware\.vibrator-service u:object_r:hal_vibrator_default_exec:s0"
        echo "/vendor/etc/init/vendor\.samsung\.hardware\.vibrator-default\.rc u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/vintf/manifest/vendor\.samsung\.hardware\.vibrator-default\.xml u:object_r:vendor_configs_file:s0"
        echo "/vendor/lib64/vendor\.samsung\.hardware\.vibrator-V3-ndk_platform\.so u:object_r:vendor_file:s0"
    } >> "$WORK_DIR/configs/file_context-vendor"
fi
if ! grep -q "vibrator-default" "$WORK_DIR/configs/fs_config-vendor"; then
    {
        echo "vendor/bin/hw/vendor.samsung.hardware.vibrator-service 0 2000 755 capabilities=0x0"
        echo "vendor/etc/init/vendor.samsung.hardware.vibrator-default.rc 0 0 644 capabilities=0x0"
        echo "vendor/etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml 0 0 644 capabilities=0x0"
        echo "vendor/lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-vendor"
fi

echo "Remove DualDAR mount points"
sed -i "/keydata/d" "$WORK_DIR/vendor/etc/fstab.qcom"
sed -i "/keyrefuge/d" "$WORK_DIR/vendor/etc/fstab.qcom"

echo "Fix NFC for G781B"
if ! grep -q "G781B" "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"; then
    {
        echo ""
        echo "on property:ro.boot.em.model=SM-G781B"
        echo "    setprop ro.boot.product.hardware.sku \"s3fwrn5\""
        echo "    setprop ro.vendor.nfc.feature.chipname \"SLSI\""
    } >> "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"
fi
