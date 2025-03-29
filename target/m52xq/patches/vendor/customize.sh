ADD_TO_WORK_DIR "a52sxqxx" "vendor" "." 0 2000 755 "u:object_r:vendor_file:s0"

DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiBLURDETECT_Stage1_V140_FP32.tflite"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiBLURDETECT_Stage2_V130_FP32.tflite"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiDEBLUR_INT16_V0132_sm7325_snpe1502.dlc"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiDENOISE_FP16_V900.caffemodel"
DELETE_FROM_WORK_DIR "vendor" "etc/midas/SRIBMidas_aiUNIFIED_FP16_V610.caffemodel"

echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"

if ! grep -q "vendor_firmware_file (file (mounton" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
    echo "(allow init_30_0 vendor_firmware_file (file (mounton)))" >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
fi
