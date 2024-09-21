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

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

sed -i "s/SoundBooster_ver1100/SoundBooster_ver1050/g" "$WORK_DIR/configs/file_context-system"
sed -i "s/SoundBooster_ver1100/SoundBooster_ver1050/g" "$WORK_DIR/configs/fs_config-system"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.security.secureclock-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/lib_SoundBooster_ver1100.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/android.hardware.security.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/lib_SoundBooster_ver1100.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdk_native_keymint.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhdcp_client_aidl.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhdcp2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libremotedisplay_wfd.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libremotedisplayservice.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libsecuibc.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstagefright_hdcp.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.keymint-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/wfd_log.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiBLURDETECT_Stage1_V140_FP32.tflite"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiBLURDETECT_Stage2_V130_FP32.tflite"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/midas/SRIBMidas_aiDEBLUR_FP16_V0132.dlc"
if ! grep -q "remotedisplay_wfd" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.adaptivebrightnessgo\.cameralightsensor\.xml u:object_r:system_file:s0"
        echo "/system/etc/permissions/privapp-permissions-com\.sec\.android\.app\.fm\.xml u:object_r:system_file:s0"
        echo "/system/etc/sysconfig/preinstalled-packages-com\.qualcomm\.qti\.services\.secureui\.xml u:object_r:system_file:s0"
        echo "/system/etc/sysconfig/preinstalled-packages-com\.sec\.android\.app\.fm\.xml u:object_r:system_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@3\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@4\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/android\.hardware\.keymaster@4\.1\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libdk_native_keymaster\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libfmradio_jni\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libhdcp2\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libkeymaster4_1support\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libkeymaster4support\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libremotedisplay_wfd\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libremotedisplayservice\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libsecuibc\.so u:object_r:system_lib_file:s0"
        echo "/system/lib/libstagefright_hdcp\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libdk_native_keymaster\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libfmradio_jni\.so u:object_r:system_lib_file:s0"
        echo "/system/priv-app/CameraLightSensor u:object_r:system_file:s0"
        echo "/system/priv-app/CameraLightSensor/CameraLightSensor\.apk u:object_r:system_file:s0"
        echo "/system/priv-app/HybridRadio u:object_r:system_file:s0"
        echo "/system/priv-app/HybridRadio/HybridRadio\.apk u:object_r:system_file:s0"
        echo "/system/system_ext/app/com\.qualcomm\.qti\.services\.secureui u:object_r:system_file:s0"
        echo "/system/system_ext/app/com\.qualcomm\.qti\.services\.secureui/com\.qualcomm\.qti\.services\.secureui\.apk u:object_r:system_file:s0"
        echo "/system/system_ext/lib/fm_helium\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib/libbeluga\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib/libfm-hci\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib/vendor\.qti\.hardware\.fm@1\.0\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib64/fm_helium\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib64/libbeluga\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib64/libfm-hci\.so u:object_r:system_lib_file:s0"
        echo "/system/system_ext/lib64/vendor\.qti\.hardware\.fm@1\.0\.so u:object_r:system_lib_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "remotedisplay_wfd" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/etc/permissions/privapp-permissions-com.samsung.adaptivebrightnessgo.cameralightsensor.xml 0 0 644 capabilities=0x0"
        echo "system/etc/permissions/privapp-permissions-com.sec.android.app.fm.xml 0 0 644 capabilities=0x0"
        echo "system/etc/sysconfig/preinstalled-packages-com.qualcomm.qti.services.secureui.xml 0 0 644 capabilities=0x0"
        echo "system/etc/sysconfig/preinstalled-packages-com.sec.android.app.fm.xml 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@3.0.so 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@4.0.so 0 0 644 capabilities=0x0"
        echo "system/lib/android.hardware.keymaster@4.1.so 0 0 644 capabilities=0x0"
        echo "system/lib/libdk_native_keymaster.so 0 0 644 capabilities=0x0"
        echo "system/lib/libfmradio_jni.so 0 0 644 capabilities=0x0"
        echo "system/lib/libhdcp2.so 0 0 644 capabilities=0x0"
        echo "system/lib/libkeymaster4_1support.so 0 0 644 capabilities=0x0"
        echo "system/lib/libkeymaster4support.so 0 0 644 capabilities=0x0"
        echo "system/lib/libremotedisplay_wfd.so 0 0 644 capabilities=0x0"
        echo "system/lib/libremotedisplayservice.so 0 0 644 capabilities=0x0"
        echo "system/lib/libsecuibc.so 0 0 644 capabilities=0x0"
        echo "system/lib/libstagefright_hdcp.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libdk_native_keymaster.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libfmradio_jni.so 0 0 644 capabilities=0x0"
        echo "system/priv-app/CameraLightSensor 0 0 755 capabilities=0x0"
        echo "system/priv-app/CameraLightSensor/CameraLightSensor.apk 0 0 644 capabilities=0x0"
        echo "system/priv-app/HybridRadio 0 0 755 capabilities=0x0"
        echo "system/priv-app/HybridRadio/HybridRadio.apk 0 0 644 capabilities=0x0"
        echo "system/system_ext/app/com.qualcomm.qti.services.secureui 0 0 755 capabilities=0x0"
        echo "system/system_ext/app/com.qualcomm.qti.services.secureui/com.qualcomm.qti.services.secureui.apk 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib/fm_helium.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib/libbeluga.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib/libfm-hci.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib/vendor.qti.hardware.fm@1.0.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib64/fm_helium.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib64/libbeluga.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib64/libfm-hci.so 0 0 644 capabilities=0x0"
        echo "system/system_ext/lib64/vendor.qti.hardware.fm@1.0.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
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
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_2X_V210_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_3X_V210_FP32\.tflite u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/midas/SRIBMidas_aiUPSCALER_4X_V210_FP32\.tflite u:object_r:vendor_configs_file:s0"
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
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_2X_V210_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_3X_V210_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/midas/SRIBMidas_aiUPSCALER_4X_V210_FP32.tflite 0 0 644 capabilities=0x0"
        echo "vendor/etc/VslMesDetector/moire_detection.tflite 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-vendor"
fi
echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"
echo "Fix RIL"
sed -i "s/1.4::IRadio/1.5::IRadio/g" "$WORK_DIR/vendor/etc/vintf/manifest.xml"

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

echo "Add stock rscmgr.rc"
ADD_TO_WORK_DIR "system" "system/etc/init/rscmgr.rc" 0 0 644 "u:object_r:system_file:s0"

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.samsung.feature.audio_fast_listenback.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.samsung.feature.audio_listenback.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.clearcameraviewcover.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.flip.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.nsflp_level_601.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.pocketsensitivitymode_level1.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.sensorhub_level29.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.wirelesscharger_authentication.xml"
echo "Add stock system features"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.minisviewwalletcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.nsflp_level_600.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketmode_level6.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.sensorhub_level34.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock NFC libs"
ADD_TO_WORK_DIR "system" "system/lib64/vendor.nxp.nxpnfc@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/vendor.nxp.nxpnfc@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
