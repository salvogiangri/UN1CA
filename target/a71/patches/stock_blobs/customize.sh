# [
ADD_TO_WORK_DIR()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    mkdir -p "$WORK_DIR/$(dirname "$FILE_PATH")"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$FILE_PATH" "$WORK_DIR/$FILE_PATH"

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
}

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

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiBLURDETECT_Stage1_V140_FP32.tflite"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiBLURDETECT_Stage2_V130_FP32.tflite"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiDEBLUR_FP16_V0132.dlc"
if ! grep -q "moire_detection" "$WORK_DIR/configs/file_context-vendor"; then
    {
        echo "/vendor/etc/midas/SRIBMQA_aiFiQA_V100_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMQA_aiIQA_V100_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMQA_aiNOISEDETECT_V100_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiCLARITY2\.0_2X_V200_FP32\.caffemodel u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiDEBLUR_V140_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiMOIREREMOVE_Coarse_V900_FP32\.caffemodel u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiMOIREREMOVE_Fine_V900_FP32\.caffemodel u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_1X_V200_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_2X_V200_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_3X_V200_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_4X_V200_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/VslMesDetector/moire_detection\.tflite u:object_r:vendor_configs_file:s0"
    } >> "$WORK_DIR/configs/file_context-vendor"
fi
if ! grep -q "moire_detection" "$WORK_DIR/configs/fs_config-vendor"; then
    {
        echo "vendor/etc/midas/SRIBMQA_aiFiQA_V100_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMQA_aiIQA_V100_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMQA_aiNOISEDETECT_V100_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiCLARITY2.0_2X_V200_FP32.caffemodel 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiDEBLUR_V140_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiMOIREREMOVE_Coarse_V900_FP32.caffemodel 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiMOIREREMOVE_Fine_V900_FP32.caffemodel 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_1X_V200_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_2X_V200_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_3X_V200_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_4X_V200_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/VslMesDetector/moire_detection.tflite 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-vendor"
fi
echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"

echo "Fix Google Assistant"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"

sed -i "s/SoundBooster_ver1100/SoundBooster_ver1050/g" "$WORK_DIR/configs/file_context-system"
sed -i "s/SoundBooster_ver1100/SoundBooster_ver1050/g" "$WORK_DIR/configs/fs_config-system"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/lib_SoundBooster_ver1100.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/lib_SoundBooster_ver1100.so"

echo "Add stock /odm/etc/permissions"
ADD_TO_WORK_DIR "odm" "etc/permissions" 0 0 755 "u:object_r:vendor_configs_file:s0"
if ! grep -q "sku_hceese" "$WORK_DIR/configs/file_context-odm"; then
    {
        echo "/odm/etc/permissions/sku_hceese u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hceese/android\.hardware\.nfc\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hceese/android\.hardware\.nfc\.ese\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hceese/com\.nxp\.mifare\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hceese/android\.hardware\.nfc\.hce\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hceese/android\.hardware\.nfc\.hcef\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hce u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hce/android\.hardware\.nfc\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hce/com\.nxp\.mifare\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hce/android\.hardware\.nfc\.hce\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hce/android\.hardware\.nfc\.hcef\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesim u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesim/android\.hardware\.nfc\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesim/com\.nxp\.mifare\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesim/android\.hardware\.nfc\.uicc\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesim/android\.hardware\.nfc\.hce\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesim/android\.hardware\.nfc\.hcef\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese/android\.hardware\.nfc\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese/android\.hardware\.nfc\.ese\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese/com\.nxp\.mifare\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese/android\.hardware\.nfc\.uicc\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese/android\.hardware\.nfc\.hce\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/permissions/sku_hcesimese/android\.hardware\.nfc\.hcef\.xml u:object_r:vendor_configs_file:s0"
    } >> "$WORK_DIR/configs/file_context-odm"
fi
if ! grep -q "sku_hceese" "$WORK_DIR/configs/fs_config-odm"; then
    {
        echo "odm/etc/permissions/sku_hceese 0 0 755 capabilities=0x0"
        echo "odm/etc/permissions/sku_hceese/android.hardware.nfc.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hceese/android.hardware.nfc.ese.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hceese/com.nxp.mifare.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hceese/android.hardware.nfc.hce.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hceese/android.hardware.nfc.hcef.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hce 0 0 755 capabilities=0x0"
        echo "odm/etc/permissions/sku_hce/android.hardware.nfc.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hce/com.nxp.mifare.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hce/android.hardware.nfc.hce.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hce/android.hardware.nfc.hcef.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesim 0 0 755 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesim/android.hardware.nfc.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesim/com.nxp.mifare.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesim/android.hardware.nfc.uicc.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesim/android.hardware.nfc.hce.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesim/android.hardware.nfc.hcef.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese 0 0 755 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese/android.hardware.nfc.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese/android.hardware.nfc.ese.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese/com.nxp.mifare.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese/android.hardware.nfc.uicc.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese/android.hardware.nfc.hce.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/permissions/sku_hcesimese/android.hardware.nfc.hcef.xml 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Add stock /odm/etc/vintf"
ADD_TO_WORK_DIR "odm" "etc/vintf" 0 0 755 "u:object_r:vendor_configs_file:s0"
if ! grep -q "manifest_hce" "$WORK_DIR/configs/file_context-odm"; then
    {
        echo "/odm/etc/vintf/manifest_disabled\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/vintf/manifest_hceese\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/vintf/manifest_hcesim\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/vintf/manifest_hcesimese\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/vintf/manifest\.xml u:object_r:vendor_configs_file:s0"
        echo "/odm/etc/vintf/manifest_hce\.xml u:object_r:vendor_configs_file:s0"
    } >> "$WORK_DIR/configs/file_context-odm"
fi
if ! grep -q "manifest_hce" "$WORK_DIR/configs/fs_config-odm"; then
    {
        echo "odm/etc/vintf/manifest_disabled.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/vintf/manifest_hceese.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/vintf/manifest_hcesim.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/vintf/manifest_hcesimese.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/vintf/manifest.xml 0 0 644 capabilities=0x0"
        echo "odm/etc/vintf/manifest_hce.xml 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Add stock /odm/etc/media_profiles_V1_0.xml"
ADD_TO_WORK_DIR "odm" "etc/media_profiles_V1_0.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"

echo "Add stock NFC libs"
ADD_TO_WORK_DIR "system" "system/lib64/vendor.nxp.nxpnfc@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/vendor.nxp.nxpnfc@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
