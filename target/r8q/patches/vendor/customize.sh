DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp2.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplay_wfd.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplayservice.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsecuibc.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libstagefright_hdcp.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/wfd_log.so"

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

DELETE_FROM_WORK_DIR "vendor" "bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiBLURDETECT_Stage1_V140_FP32.tflite"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiBLURDETECT_Stage2_V130_FP32.tflite"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiDEBLUR_FP16_V0132.caffemodel"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiDENOISE_FP16_V900.caffemodel"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiUNIFIED_FP16_V610.caffemodel"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.0.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.1.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.2.so"

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

echo "Fix NFC for G781B"
if ! grep -q "G781B" "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"; then
    {
        echo ""
        echo "on property:ro.boot.em.model=SM-G781B"
        echo "    setprop ro.boot.product.hardware.sku \"s3fwrn5\""
        echo "    setprop ro.vendor.nfc.feature.chipname \"SLSI\""
        echo ""
        echo "on property:ro.boot.em.model=SM-G7810"
        echo "    setprop ro.boot.product.hardware.sku \"s3fwrn5\""
        echo "    setprop ro.vendor.nfc.feature.chipname \"SLSI\""
        echo ""
        echo "on property:ro.boot.em.model=SM-G781N"
        echo "    setprop ro.boot.product.hardware.sku \"s3fwrn5\""
        echo "    setprop ro.vendor.nfc.feature.chipname \"SLSI\""
    } >> "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"
fi
