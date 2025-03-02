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
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libsecuibc.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstagefright_hdcp.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/wfd_log.so"

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
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiBLURDETECT_Stage1_V140_FP32.tflite"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiBLURDETECT_Stage2_V130_FP32.tflite"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiDEBLUR_FP16_V0132.caffemodel"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiDENOISE_FP16_V900.caffemodel"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiUNIFIED_FP16_V610.caffemodel"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.vibrator@2.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.vibrator@2.1.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.vibrator@2.2.so"

echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"

if ! grep -q "vibrator-default" "$WORK_DIR/configs/file_context-vendor"; then
    {
        echo "/vendor/bin/hw/vendor\.samsung\.hardware\.vibrator-service u:object_r:hal_vibrator_default_exec:s0"
        echo "/vendor/etc/init/vendor\.samsung\.hardware\.vibrator-default\.rc u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiCLARITY2\.0_2X_V200_FP32\.caffemodel u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiDEBLUR_V140_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_1X_V200_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_2X_V210_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_3X_V210_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_4X_V210_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMQA_aiFiQA_V100_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMQA_aiIQA_V100_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMQA_aiNOISEDETECT_V100_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/vintf/manifest/vendor\.samsung\.hardware\.vibrator-default\.xml u:object_r:vendor_configs_file:s0"
        echo "/vendor/lib64/vendor\.samsung\.hardware\.vibrator-V3-ndk_platform\.so u:object_r:vendor_file:s0"
    } >> "$WORK_DIR/configs/file_context-vendor"
fi
if ! grep -q "vibrator-default" "$WORK_DIR/configs/fs_config-vendor"; then
    {
        echo "vendor/bin/hw/vendor.samsung.hardware.vibrator-service 0 2000 755 capabilities=0x0"
        echo "vendor/etc/init/vendor.samsung.hardware.vibrator-default.rc 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiCLARITY2.0_2X_V200_FP32.caffemodel  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiDEBLUR_V140_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_1X_V200_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_2X_V210_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_3X_V210_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_4X_V210_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMQA_aiFiQA_V100_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMQA_aiIQA_V100_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMQA_aiNOISEDETECT_V100_FP32.tflite  0 0 644 capabilities=0x0"
        echo "vendor/etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml 0 0 644 capabilities=0x0"
        echo "vendor/lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-vendor"
fi

echo "Remove DualDAR mount points"
sed -i "/keydata/d" "$WORK_DIR/vendor/etc/fstab.qcom"
sed -i "/keyrefuge/d" "$WORK_DIR/vendor/etc/fstab.qcom"

echo "Set up File-based Encryption V2"
sed -i "s|fileencryption=ice|fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,keydirectory=/metadata/vold/metadata_encryption,sysfs_path=/sys/devices/platform/soc/1d84000.ufshc|" "$WORK_DIR/vendor/etc/fstab.qcom"

echo "Disable NFC for Japanese variants"
if ! grep -q "SCG01" "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"; then
    {
        echo ""
        echo "on property:ro.boot.em.model=SC-51A"
        echo "    stop vendor.nfc_hal_service"
        echo "    stop vendor.secure_element_hal_service"
        echo ""
        echo "on property:ro.boot.em.model=SCG01"
        echo "    stop vendor.nfc_hal_service"
        echo "    stop vendor.secure_element_hal_service"
    } >> "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"
fi
