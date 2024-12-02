# [
DECOMPILE()
{
    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        bash "$SRC_DIR/scripts/apktool.sh" d "$1"
    fi
}

APPLY_PATCH()
{
    local PATCH
    local OUT

    DECOMPILE "$1"

    cd "$APKTOOL_DIR/$1"
    PATCH="$SRC_DIR/unica/patches/product_feature/$2"
    OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
        || echo "$OUT" | grep -q "Skipping patch" || false
    patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
    cd - &> /dev/null
}

GET_FP_SENSOR_TYPE()
{
    if [[ "$1" == *"ultrasonic"* ]]; then
        echo "ultrasonic"
    elif [[ "$1" == *"optical"* ]]; then
        echo "optical"
    elif [[ "$1" == *"side"* ]]; then
        echo "side"
    else
        echo "Unsupported type: $1"
        exit 1
    fi
}

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
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [[ "$SOURCE_PRODUCT_FIRST_API_LEVEL" != "$TARGET_PRODUCT_FIRST_API_LEVEL" ]]; then
    echo "Applying MAINLINE_API_LEVEL patches"

    DECOMPILE "system/framework/esecomm.jar"
    DECOMPILE "system/framework/services.jar"

    FTP="
    system/framework/esecomm.jar/smali/com/sec/esecomm/EsecommAdapter.smali
    system/framework/services.jar/smali/com/android/server/SystemServer.smali
    system/framework/services.jar/smali_classes2/com/android/server/enterprise/hdm/HdmVendorController.smali
    system/framework/services.jar/smali_classes2/com/android/server/knox/dar/ddar/ta/TAProxy.smali
    system/framework/services.jar/smali_classes3/com/android/server/power/PowerManagerUtil.smali
    "
    for f in $FTP; do
        sed -i \
            "s/\"MAINLINE_API_LEVEL: $SOURCE_PRODUCT_FIRST_API_LEVEL\"/\"MAINLINE_API_LEVEL: $TARGET_PRODUCT_FIRST_API_LEVEL\"/g" \
            "$APKTOOL_DIR/$f"
        sed -i "s/\"$SOURCE_PRODUCT_FIRST_API_LEVEL\"/\"$TARGET_PRODUCT_FIRST_API_LEVEL\"/g" "$APKTOOL_DIR/$f"
    done
fi

if $SOURCE_AUDIO_SUPPORT_ACH_RINGTONE; then
    if ! $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
        echo "Applying ACH ringtone patches"
        APPLY_PATCH "system/framework/framework.jar" "audio/ach/framework.jar/0001-Disable-ACH-ringtone-support.patch"
    fi
else
    if $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
        # TODO: won't be necessary anyway
        true
    fi
fi

if $SOURCE_AUDIO_SUPPORT_DUAL_SPEAKER; then
    if ! $TARGET_AUDIO_SUPPORT_DUAL_SPEAKER; then
        echo "Applying dual speaker patches"
        APPLY_PATCH "system/framework/framework.jar" "audio/dual_speaker/framework.jar/0001-Disable-dual-speaker-support.patch"
        APPLY_PATCH "system/framework/services.jar" "audio/dual_speaker/services.jar/0001-Disable-dual-speaker-support.patch"
    fi
else
    if $TARGET_AUDIO_SUPPORT_DUAL_SPEAKER; then
        # TODO: won't be necessary anyway
        true
    fi
fi

if $SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION; then
    if ! $TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION; then
        echo "Applying virtual vibration patches"
        APPLY_PATCH "system/framework/framework.jar" "audio/virtual_vib/framework.jar/0001-Disable-virtual-vibration-support.patch"
        APPLY_PATCH "system/framework/services.jar" "audio/virtual_vib/services.jar/0001-Disable-virtual-vibration-support.patch"
        APPLY_PATCH "system/priv-app/SecSettings/SecSettings.apk" "audio/virtual_vib/SecSettings.apk/0001-Disable-virtual-vibration-support.patch"
        APPLY_PATCH "system/priv-app/SettingsProvider/SettingsProvider.apk" "audio/virtual_vib/SettingsProvider.apk/0001-Disable-virtual-vibration-support.patch"
    fi
else
    if $TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION; then
        # TODO: won't be necessary anyway
        true
    fi
fi

if [[ "$SOURCE_AUTO_BRIGHTNESS_TYPE" != "$TARGET_AUTO_BRIGHTNESS_TYPE" ]]; then
    echo "Applying auto brightness type patches"

    DECOMPILE "system/framework/services.jar"
    DECOMPILE "system/framework/ssrm.jar"
    DECOMPILE "system/priv-app/SecSettings/SecSettings.apk"

    FTP="
    system/framework/services.jar/smali_classes3/com/android/server/power/PowerManagerUtil.smali
    system/framework/ssrm.jar/smali/com/android/server/ssrm/PreMonitor.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/Rune.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_AUTO_BRIGHTNESS_TYPE\"/\"$TARGET_AUTO_BRIGHTNESS_TYPE\"/g" "$APKTOOL_DIR/$f"
    done
fi

if [[ "$(GET_FP_SENSOR_TYPE "$SOURCE_FP_SENSOR_CONFIG")" != "$(GET_FP_SENSOR_TYPE "$TARGET_FP_SENSOR_CONFIG")" ]]; then
    echo "Applying fingerprint sensor patches"

    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/framework/services.jar"
    DECOMPILE "system/priv-app/SecSettings/SecSettings.apk"
    DECOMPILE "system_ext/priv-app/SystemUI/SystemUI.apk"

    FTP="
    system/framework/framework.jar/smali_classes2/android/hardware/fingerprint/FingerprintManager.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/bio/fingerprint/SemFingerprintManager.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/bio/fingerprint/SemFingerprintManager\$Characteristics.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/rune/CoreRune.smali
    system/framework/services.jar/smali/com/android/server/biometrics/sensors/fingerprint/FingerprintUtils.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/biometrics/fingerprint/FingerprintSettingsUtils.smali
    "
    for f in $FTP; do
        sed -i "s/$SOURCE_FP_SENSOR_CONFIG/$TARGET_FP_SENSOR_CONFIG/g" "$APKTOOL_DIR/$f"
    done

    # TODO: handle ultrasonic devices
    if [[ "$(GET_FP_SENSOR_TYPE "$TARGET_FP_SENSOR_CONFIG")" == "optical" ]]; then
        if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
            cp -a --preserve=all "$SRC_DIR/unica/patches/product_feature/fingerprint/optical_fod/system/"* "$WORK_DIR/system/system"
            APPLY_PATCH "system/priv-app/SecSettings/SecSettings.apk" "fingerprint/SecSettings.apk/0001-Enable-isOpticalSensor.patch"
            APPLY_PATCH "system_ext/priv-app/SystemUI/SystemUI.apk" "fingerprint/SystemUI.apk/0001-Add-optical-FOD-support.patch"
        fi
    elif [[ "$(GET_FP_SENSOR_TYPE "$TARGET_FP_SENSOR_CONFIG")" == "side" ]]; then
        if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
            cp -a --preserve=all "$SRC_DIR/unica/patches/product_feature/fingerprint/side_fp/system/"* "$WORK_DIR/system/system"
            APPLY_PATCH "system/framework/services.jar" "fingerprint/services.jar/0001-Disable-SECURITY_FINGERPRINT_IN_DISPLAY.patch"
            APPLY_PATCH "system/priv-app/SecSettings/SecSettings.apk" "fingerprint/SecSettings.apk/0001-Enable-isSideSensor.patch"
            APPLY_PATCH "system_ext/priv-app/SystemUI/SystemUI.apk" "fingerprint/SystemUI.apk/0001-Add-side-fingerprint-sensor-support.patch"
        elif [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
            #TODO: handle essi side fingerprint
            true
        fi
    fi

    if [[ "$TARGET_FP_SENSOR_CONFIG" == *"navi=1"* ]]; then
        APPLY_PATCH "system/framework/services.jar" \
            "fingerprint/services.jar/0001-Enable-FP_FEATURE_GESTURE_MODE.patch"
    fi
    if [[ "$TARGET_FP_SENSOR_CONFIG" == *"no_delay_in_screen_off"* ]]; then
        APPLY_PATCH "system/priv-app/BiometricSetting/BiometricSetting.apk" \
            "fingerprint/BiometricSetting.apk/0001-Enable-FP_FEATURE_NO_DELAY_IN_SCREEN_OFF.patch"
    fi
fi

if [[ "$TARGET_API_LEVEL" -lt 34 ]]; then
    echo "Applying Face HIDL patches"
    APPLY_PATCH "system/framework/services.jar" "face/services.jar/0001-Fallback-to-Face-HIDL-2.0.patch"
fi

if [[ "$SOURCE_MDNIE_SUPPORTED_MODES" != "$TARGET_MDNIE_SUPPORTED_MODES" ]] || \
    [[ "$SOURCE_MDNIE_WEAKNESS_SOLUTION_FUNCTION" != "$TARGET_MDNIE_WEAKNESS_SOLUTION_FUNCTION" ]]; then
    echo "Applying mDNIe features patches"

    DECOMPILE "system/framework/services.jar"

    FTP="
    system/framework/services.jar/smali_classes2/com/samsung/android/hardware/display/SemMdnieManagerService.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_MDNIE_SUPPORTED_MODES\"/\"$TARGET_MDNIE_SUPPORTED_MODES\"/g" "$APKTOOL_DIR/$f"
        sed -i "s/\"$SOURCE_MDNIE_WEAKNESS_SOLUTION_FUNCTION\"/\"$TARGET_MDNIE_WEAKNESS_SOLUTION_FUNCTION\"/g" "$APKTOOL_DIR/$f"
    done
fi
if $SOURCE_HAS_HW_MDNIE; then
    if ! $TARGET_HAS_HW_MDNIE; then
        echo "Applying HW mDNIe patches"
        SET_CONFIG "SEC_FLOATING_FEATURE_LCD_SUPPORT_MDNIE_HW" --delete
        APPLY_PATCH "system/framework/framework.jar" "mdnie/hw/framework.jar/0001-Disable-HW-mDNIe.patch"
        APPLY_PATCH "system/framework/services.jar" "mdnie/hw/services.jar/0001-Disable-HW-mDNIe.patch"
    fi
else
    if $TARGET_HAS_HW_MDNIE; then
        # TODO: add HW mDNIe support
        true
    fi
fi
if $SOURCE_MDNIE_SUPPORT_HDR_EFFECT; then
    if ! $TARGET_MDNIE_SUPPORT_HDR_EFFECT; then
        echo "Applying mDNIe HDR effect patches"
        SET_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT" --delete
        APPLY_PATCH "system/priv-app/SecSettings/SecSettings.apk" "mdnie/hdr/SecSettings.apk/0001-Disable-HDR-Settings.patch"
        APPLY_PATCH "system/priv-app/SettingsProvider/SettingsProvider.apk" "mdnie/hdr/SettingsProvider.apk/0001-Disable-HDR-Settings.patch"
    fi
else
    if $TARGET_MDNIE_SUPPORT_HDR_EFFECT; then
        # TODO: won't be necessary anyway
        true
    fi
fi

if ! $SOURCE_HAS_QHD_DISPLAY; then
    if $TARGET_HAS_QHD_DISPLAY; then
        echo "Applying multi resolution patches"
        if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
            cp -a --preserve=all "$SRC_DIR/unica/patches/product_feature/resolution/qssi/system/"* "$WORK_DIR/system/system"
        elif [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
            cp -a --preserve=all "$SRC_DIR/unica/patches/product_feature/resolution/essi/system/"* "$WORK_DIR/system/system"
        fi
        APPLY_PATCH "system/framework/framework.jar" "resolution/multi_res/framework.jar/0001-Enable-dynamic-resolution-control.patch"
        APPLY_PATCH "system/priv-app/SecSettings/SecSettings.apk" "resolution/multi_res/SecSettings.apk/0001-Enable-dynamic-resolution-control.patch"
    fi
else
    if ! $TARGET_HAS_QHD_DISPLAY; then
        # TODO: won't be necessary anyway
        true
    fi
fi

if [[ "$SOURCE_HFR_MODE" != "$TARGET_HFR_MODE" ]]; then
    echo "Applying HFR_MODE patches"

    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/framework/gamemanager.jar"
    DECOMPILE "system/framework/gamesdk.jar"
    DECOMPILE "system/framework/secinputdev-service.jar"
    DECOMPILE "system/priv-app/SecSettings/SecSettings.apk"
    DECOMPILE "system/priv-app/SettingsProvider/SettingsProvider.apk"
    DECOMPILE "system_ext/priv-app/SystemUI/SystemUI.apk"

    # TODO: this breaks 60hz AOD
    #if [[ "${#TARGET_HFR_MODE}" -le "6" ]]; then
    if [[ "$TARGET_HFR_MODE" -le "1" ]]; then
        if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
            APPLY_PATCH "system_ext/priv-app/SystemUI/SystemUI.apk" "hfr/SystemUI.apk/0001-Nuke-KEYGUARD_ADJUST_REFRESH_RATE.patch"
        fi
    fi

    FTP="
    system/framework/framework.jar/smali_classes5/com/samsung/android/hardware/display/RefreshRateConfig.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/rune/CoreRune.smali
    system/framework/gamemanager.jar/smali/com/samsung/android/game/GameManagerService.smali
    system/framework/gamesdk.jar/smali/com/samsung/android/gamesdk/vrr/GameSDKVrrManager.smali
    system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputDeviceManagerService.smali
    system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputFeatures.smali
    system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputFeaturesExtra.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
    system/priv-app/SettingsProvider/SettingsProvider.apk/smali/com/android/providers/settings/DatabaseHelper.smali
    system_ext/priv-app/SystemUI/SystemUI.apk/smali/com/android/systemui/LsRune.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_HFR_MODE\"/\"$TARGET_HFR_MODE\"/g" "$APKTOOL_DIR/$f"
    done
fi
if [[ "$SOURCE_HFR_SUPPORTED_REFRESH_RATE" != "$TARGET_HFR_SUPPORTED_REFRESH_RATE" ]]; then
    echo "Applying HFR_SUPPORTED_REFRESH_RATE patches"

    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/priv-app/SecSettings/SecSettings.apk"

    FTP="
    system/framework/framework.jar/smali_classes5/com/samsung/android/hardware/display/RefreshRateConfig.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
    "
    for f in $FTP; do
        if [[ "$TARGET_HFR_SUPPORTED_REFRESH_RATE" != "none" ]]; then
            sed -i "s/\"$SOURCE_HFR_SUPPORTED_REFRESH_RATE\"/\"$TARGET_HFR_SUPPORTED_REFRESH_RATE\"/g" "$APKTOOL_DIR/$f"
        else
            sed -i "s/\"$SOURCE_HFR_SUPPORTED_REFRESH_RATE\"/\"\"/g" "$APKTOOL_DIR/$f"
        fi
    done
fi
if [[ "$SOURCE_HFR_DEFAULT_REFRESH_RATE" != "$TARGET_HFR_DEFAULT_REFRESH_RATE" ]]; then
    echo "Applying HFR_DEFAULT_REFRESH_RATE patches"

    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/priv-app/SecSettings/SecSettings.apk"
    DECOMPILE "system/priv-app/SettingsProvider/SettingsProvider.apk"

    FTP="
    system/framework/framework.jar/smali_classes5/com/samsung/android/hardware/display/RefreshRateConfig.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
    system/priv-app/SettingsProvider/SettingsProvider.apk/smali/com/android/providers/settings/DatabaseHelper.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_HFR_DEFAULT_REFRESH_RATE\"/\"$TARGET_HFR_DEFAULT_REFRESH_RATE\"/g" "$APKTOOL_DIR/$f"
    done
fi
if [[ "$SOURCE_HFR_SEAMLESS_BRT" != "$TARGET_HFR_SEAMLESS_BRT" ]] || \
    [[ "$SOURCE_HFR_SEAMLESS_LUX" != "$TARGET_HFR_SEAMLESS_LUX" ]]; then
    echo "Applying HFR_SEAMLESS_BRT/HFR_SEAMLESS_LUX patches"

    if [[ "$TARGET_HFR_SEAMLESS_BRT" == "none" ]] && [[ "$TARGET_HFR_SEAMLESS_LUX" == "none" ]]; then
        if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
            APPLY_PATCH "system/framework/framework.jar" "hfr/qssi/framework.jar/0001-Remove-brightness-threshold-values.patch"
        elif [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
            APPLY_PATCH "system/framework/framework.jar" "hfr/essi/framework.jar/0001-Remove-brightness-threshold-values.patch"
        fi
    else
        DECOMPILE "system/framework/framework.jar"

        FTP="
        system/framework/framework.jar/smali_classes5/com/samsung/android/hardware/display/RefreshRateConfig.smali
        "
        for f in $FTP; do
            sed -i "s/\"$SOURCE_HFR_SEAMLESS_BRT\"/\"$TARGET_HFR_SEAMLESS_BRT\"/g" "$APKTOOL_DIR/$f"
            sed -i "s/\"$SOURCE_HFR_SEAMLESS_LUX\"/\"$TARGET_HFR_SEAMLESS_LUX\"/g" "$APKTOOL_DIR/$f"
        done
    fi
fi

if [[ "$SOURCE_MULTI_MIC_MANAGER_VERSION" != "$TARGET_MULTI_MIC_MANAGER_VERSION" ]]; then
    echo "Applying SemMultiMicManager patches"

    DECOMPILE "system/framework/framework.jar"

    FTP="
    system/framework/framework.jar/smali_classes5/com/samsung/android/camera/mic/SemMultiMicManager.smali
    "
    for f in $FTP; do
        sed -i "s/$SOURCE_MULTI_MIC_MANAGER_VERSION/$TARGET_MULTI_MIC_MANAGER_VERSION/g" "$APKTOOL_DIR/$f"
    done
fi

if [[ "$SOURCE_SSRM_CONFIG_NAME" != "$TARGET_SSRM_CONFIG_NAME" ]]; then
    echo "Applying SSRM patches"

    DECOMPILE "system/framework/ssrm.jar"

    FTP="
    system/framework/ssrm.jar/smali/com/android/server/ssrm/Feature.smali
    "
    for f in $FTP; do
        sed -i "s/$SOURCE_SSRM_CONFIG_NAME/$TARGET_SSRM_CONFIG_NAME/g" "$APKTOOL_DIR/$f"
    done
fi
if [[ "$SOURCE_DVFS_CONFIG_NAME" != "$TARGET_DVFS_CONFIG_NAME" ]]; then
    echo "Applying DVFS patches"

    DECOMPILE "system/framework/ssrm.jar"

    FTP="
    system/framework/ssrm.jar/smali/com/android/server/ssrm/Feature.smali
    "
    for f in $FTP; do
        sed -i "s/$SOURCE_DVFS_CONFIG_NAME/$TARGET_DVFS_CONFIG_NAME/g" "$APKTOOL_DIR/$f"
    done
fi

if $SOURCE_IS_ESIM_SUPPORTED; then
    if ! $TARGET_IS_ESIM_SUPPORTED; then
        SET_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" --delete
        SET_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_EMBEDDED_SIM" --delete
    fi
fi

if [ ! -f "$FW_DIR/${MODEL}_${REGION}/vendor/etc/permissions/android.hardware.strongbox_keystore.xml" ]; then
    echo "Applying strongbox patches"
    APPLY_PATCH "system/framework/framework.jar" "strongbox/framework.jar/0001-Disable-StrongBox-in-DevRootKeyATCmd.patch"
fi
