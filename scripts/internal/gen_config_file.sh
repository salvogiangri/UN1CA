#!/usr/bin/env bash
#
# Copyright (C) 2025 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# [
source "$SRC_DIR/scripts/utils/common_utils.sh" || exit 1

trap '[ $? -ne 0 ] && rm -f "$OUT_DIR/config.sh"' EXIT

GET_BUILD_VAR()
{
    if [ "$2" ]; then
        if [ ! "${!1}" ]; then
            echo "${1}=\"${2}\""
            return 0
        fi
    else
        _CHECK_NON_EMPTY_PARAM "$1" "${!1}" || exit 1
    fi

    echo "${1}=\"${!1}\""
    return 0
}

IS_UNICA_CERT_AVAILABLE()
{
    local PLATFORM_KEY_SHA1="5b0eb951718acc596370dabab83f546e779b21dc"
    local OTA_KEY_SHA1="681aa9d28fe5fc60be8c25dc5f26a73ec3d6fb46"

    local USES_UNICA_CERT="false"
    if [[ "$(sha1sum "$SRC_DIR/security/unica_platform.pk8" 2> /dev/null | cut -d " " -f 1)" == "$PLATFORM_KEY_SHA1" ]] && \
            [[ "$(sha1sum "$SRC_DIR/security/unica_ota.pk8" 2> /dev/null | cut -d " " -f 1)" == "$OTA_KEY_SHA1" ]]; then
        USES_UNICA_CERT="true"
    fi

    echo "$USES_UNICA_CERT"
}
# ]

if [ $# -ne 1 ]; then
    echo "Usage: gen_config_file <target>" >&2
    exit 1
elif [ ! -f "$SRC_DIR/target/$1/config.sh" ]; then
    LOGE "File not found: target/$1/config.sh"
    exit 1
else
    source "$SRC_DIR/unica/configs/version.sh" || exit 1
    source "$SRC_DIR/target/$1/config.sh" || exit 1
    if [ -f "$SRC_DIR/platform/$TARGET_PLATFORM/config.sh" ]; then
        # HACK
        source "$SRC_DIR/platform/$TARGET_PLATFORM/config.sh" || exit
        source "$SRC_DIR/target/$1/config.sh" || exit 1
    fi
fi

if [ ! "$TARGET_OS_SINGLE_SYSTEM_IMAGE" ]; then
    LOGE "TARGET_OS_SINGLE_SYSTEM_IMAGE is not set!"
    exit 1
elif [ ! -f "$SRC_DIR/unica/configs/$TARGET_OS_SINGLE_SYSTEM_IMAGE.sh" ]; then
    LOGE "\"$TARGET_OS_SINGLE_SYSTEM_IMAGE\" is not a valid system image"
    exit 1
else
    source "$SRC_DIR/unica/configs/$TARGET_OS_SINGLE_SYSTEM_IMAGE.sh" || exit 1
fi

if [ -f "$OUT_DIR/config.sh" ]; then
    LOGW "config.sh already exists. Regenerating"
    rm -f "$OUT_DIR/config.sh"
fi

# The following environment variables are considered during execution:
#
#   ROM_VERSION
#     String containing the version name in the format of "x.y.z-xxxxxxxx",
#     it is set in unica/configs/version.sh.
#
#   ROM_BUILD_TIMESTAMP
#     Integer containing the build timestamp in seconds, this is used by the UN1CA Updates app.
#     Defaults to the current time of execution of the script.
#
#   [SOURCE/TARGET]_FIRMWARE
#     String containing the source/target device firmware to use in the format of "Model number/CSC/IMEI".
#     IMEI number is necessary to fetch the firmware from FUS, alternatively the device serial number can be used.
#
#   [SOURCE/TARGET]_EXTRA_FIRMWARES
#     If defined, this set of extra devices firmwares will be downloaded/extracted when running `download_fw`/`extract_fw`
#     along with the ones set in [SOURCE/TARGET]_FIRMWARE.
#     This variable must be set as a string array in bash syntax, with each string element having the format of "Model number/CSC/IMEI".
#     Please note that due to bash limitations the variable will be stored as a string with each item delimited using ":".
#
#     Example:
#       - Setting the variable: `SOURCE_EXTRA_FIRMWARES=("SM-A528B/BTU/352599501234566" "SM-A528N/KOO/354049881234560")`
#       - Converting back to array: `IFS=":" read -r -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"`
#
#   TARGET_NAME
#     String containing the target device name, it must match the `SEC_FLOATING_FEATURE_SETTINGS_CONFIG_BRAND_NAME` config.
#     SoC OEM name can be appended in case the device has multiple variants with a different SoC.
#
#     Example:
#       `TARGET_NAME="Galaxy S24 (Exynos)"`
#
#   TARGET_CODENAME
#     String containing the target device codename, it must match the `ro.product.vendor.device` prop.
#
#   TARGET_PLATFORM
#     String containing the target device platform. It is optional and only used when more targets
#     use the same platform.
#
#   [SOURCE/TARGET]_PLATFORM_SDK_VERSION
#     Integer containing the SDK API level of the device firmware, it must match the `ro.build.version.sdk` prop.
#
#   [SOURCE/TARGET]_PRODUCT_SHIPPING_API_LEVEL
#     Integer containing the SDK API level that the device is initially launched with,
#     it must match the `ro.product.first_api_level` prop.
#
#   [SOURCE/TARGET]_BOARD_API_LEVEL
#     Integer containing the board API level, it must match the `ro.board.api_level` prop.
#
#   TARGET_ASSERT_MODEL
#     If defined, the zip package will use the provided model numbers with the value in the `ro.boot.em.model` prop
#     to ensure if it is compatible with the device it is currently being installed in, by default TARGET_CODENAME
#     is checked instead.
#
#     Example:
#       `TARGET_ASSERT_MODEL=("SM-A528B" "SM-A528N")`
#
#   TARGET_DISABLE_AVB_SIGNING
#     If set to true, AVB signing will be disabled.
#     Defaults to false.
#
#   TARGET_INCLUDE_PATCHED_VBMETA (DEPRECATED)
#     If set to true, a patched vbmeta image will be included in the compiled Odin tar package.
#     Only applies when TARGET_INSTALL_METHOD is set to "odin".
#     Defaults to false.
#
#   TARGET_KEEP_ORIGINAL_SIGN
#     If set to true, the original AVB/Samsung signature footer is kept in the target device kernel images.
#     Defaults to false.
#
#   TARGET_BOOT_PARTITION_SIZE
#     Integer containing the size in bytes of the target device boot partition size.
#
#   TARGET_DTBO_PARTITION_SIZE
#     Integer containing the size in bytes of the target device dtbo partition size.
#
#   TARGET_INIT_BOOT_PARTITION_SIZE
#     Integer containing the size in bytes of the target device init_boot partition size.
#
#   TARGET_VENDOR_BOOT_PARTITION_SIZE
#     Integer containing the size in bytes of the target device vendor_boot partition size.
#
#   TARGET_SUPER_PARTITION_SIZE
#     Integer containing the size in bytes of the target device super partition size, which can be checked using the lpdump tool.
#     Notice this must be bigger than TARGET_${TARGET_SUPER_GROUP_NAME}_SIZE.
#
#   [SOURCE/TARGET]_SUPER_GROUP_NAME
#     String containing the super partition group name the device uses.
#     When TARGET_SUPER_GROUP_NAME is not set, the value in SOURCE_SUPER_GROUP_NAME is used by default.
#
#   TARGET_${TARGET_SUPER_GROUP_NAME}_SIZE
#     Integer containing the size in bytes of the target device super group size, which can be checked using the lpdump tool.
#     Notice this must be smaller than TARGET_SUPER_PARTITION_SIZE.
#
#   TARGET_OS_SINGLE_SYSTEM_IMAGE
#     String containing the target device SSI, it must match the `ro.build.product` prop.
#     Currently, only "qssi", "essi" and "mssi" are supported.
#
#   TARGET_OS_FILE_SYSTEM_TYPE
#     String containing the target device firmware file system.
#     Defaults to "erofs".
#     Using a different value than stock will require patching the device fstab file in vendor and kernel ramdisk.
#
#   TARGET_OS_BUILD_SYSTEM_EXT_PARTITION
#     If set to true, system_ext partition will be built.
#
#   TARGET_OS_BOOT_DEVICE_PATH
#     String containing the path to the target device block devices.
#     Defaults to "/dev/block/bootdevice/by-name".
#
#   [SOURCE/TARGET]_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION
#     Integer containing the device RecordAlive lib version.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `version` parameter in the `com.samsung.android.camera.mic.SemMultiMicManager.isSupported()` method inside `framework.jar`
#       - Suffix number in "/vendor/lib(64)/lib_SamsungRec_*.so" lib
#
#   [SOURCE/TARGET]_AUDIO_SUPPORT_ACH_RINGTONE
#     Boolean which describes whether the device supports the "Sync vibration with ringtone" feature.
#     It can be checked in the following ways:
#       - /system/media/audio files start with "ACH_"
#       - `SEC_AUDIO_SUPPORT_ACH_RINGTONE` in the `com.samsung.android.audio.Rune` class inside `framework.jar` is set to true
#       - `SUPPORT_ACH` in the `com.samsung.android.vibrator.VibRune` class inside `framework.jar` is set to true
#
#   [SOURCE/TARGET]_AUDIO_SUPPORT_DUAL_SPEAKER
#     Boolean which describes whether the device has dual speaker support.
#     It can be checked in the following ways:
#       - `SEC_AUDIO_NUM_OF_SPEAKER` in the `com.samsung.android.audio.Rune` class inside `framework.jar` is set to "2"
#       - `SEC_AUDIO_SUPPORT_DUAL_SPEAKER` in the `com.samsung.android.audio.Rune` class inside `framework.jar` is set to true
#       - "SEC_FLOATING_FEATURE_AUDIO_SUPPORT_DUAL_SPEAKER" in floating_feature.xml is set to "TRUE"
#
#   [SOURCE/TARGET]_AUDIO_SUPPORT_VIRTUAL_VIBRATION
#     Boolean which describes whether the device supports the "Vibration sound for incoming calls" feature.
#     It can be checked in the following ways:
#       - `SEC_AUDIO_SUPPORT_VIRTUAL_VIBRATION_SOUND` in the `com.samsung.android.audio.Rune` class inside `framework.jar` is set to true
#       - `SUPPORT_VIRTUAL_VIBRATION_SOUND` in the `com.samsung.android.vibrator.VibRune` class inside `framework.jar` is set to true
#
#   [SOURCE/TARGET]_CAMERA_SUPPORT_CAMERAX_EXTENSION
#     Boolean which describes whether the device supports CameraX Extensions API.
#     It can be checked in the following ways:
#       - "ro.camerax.extensions.enabled" in "/system/build.prop" is set to "true"
#
#   [SOURCE/TARGET]_CAMERA_SUPPORT_CUTOUT_PROTECTION
#     Boolean which describes whether the device supports the camera cutout protection feature.
#     It can be checked in the following ways:
#       - "config_enableDisplayCutoutProtection" in "res/values/bools.xml" inside `SystemUI.apk` is set to "true"
#
#   [SOURCE/TARGET]_CAMERA_SUPPORT_MASS_APP_FLAVOR
#     Boolean which describes whether the device ships the mass Samsung Camera app flavor.
#     It can be checked in the following ways:
#       - `AndroidManifest.xml` of `SamsungCamera.apk` has `hal3_mass-phone-release` value
#
#   [SOURCE/TARGET]_CAMERA_SUPPORT_SDK_SERVICE
#     Boolean which describes whether the device supports the Samsung Camera SDK Service.
#
#   [SOURCE/TARGET]_COMMON_CONFIG_MDNIE_MODE
#     Integer containing the device mDNIe feature bit flag.
#     It can be checked in the following ways:
#       - `MDNIE_SUPPORT_FUNCTION` value in the `com.samsung.android.hardware.display.SemMdnieManagerService` class inside `services.jar`
#       - "SEC_FLOATING_FEATURE_COMMON_CONFIG_MDNIE_MODE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL
#     Boolean which describes whether the device has a WQHD(+) display.
#     It can be checked in the following ways:
#       - `FW_DYNAMIC_RESOLUTION_CONTROL` in the `com.samsung.android.rune.CoreRune` class inside `framework.jar` is set to true
#       - "SEC_FLOATING_FEATURE_COMMON_CONFIG_DYN_RESOLUTION_CONTROL" in floating_feature.xml is set
#
#   [SOURCE/TARGET]_COMMON_SUPPORT_EMBEDDED_SIM
#     Boolean which describes whether the device has eSIM support.
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" in floating_feature.xml is set
#
#   [SOURCE/TARGET]_COMMON_SUPPORT_HDR_EFFECT
#     Boolean which describes whether the device supports the "Video brightness" feature.
#     Defaults to true if COMMON_CONFIG_MDNIE_MODE contains the "mSupportContentModeVideoEnhance" bit (1 << 2).
#     It can be checked in the following ways:
#       - `com.samsung.android.settings.usefulfeature.videoenhancer.VideoEnhancerPreferenceController.getAvailabilityStatus()`
#         method inside `SecSettings.apk` is not UNSUPPORTED_ON_DEVICE (3)
#       - "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT" in floating_feature.xml is set to "TRUE"
#
#   [SOURCE/TARGET]_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME
#     String containing the DVFS policy file name used by SDHMS.
#     It can be checked in the following ways:
#       - `DVFS_FILENAME` value in the `com.android.server.ssrm.Feature` class inside `ssrm.jar`
#
#   [SOURCE/TARGET]_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME
#     String containing the SSRM policy file name used by SDHMS.
#     It can be checked in the following ways:
#       - `SSRM_FILENAME` value in the `com.android.server.ssrm.Feature` class inside `ssrm.jar`
#       - "SEC_FLOATING_FEATURE_SYSTEM_CONFIG_SIOP_POLICY_FILENAME" value in floating_feature.xml
#
#   [SOURCE/TARGET]_FINGERPRINT_CONFIG_SENSOR
#     String containing the fingerprint sensor feature string.
#     It can be checked in the following ways:
#       - `mConfig` value in the `com.samsung.android.bio.fingerprint.SemFingerprintManager$Characteristic` class inside `framework.jar`
#
#   [SOURCE/TARGET]_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION
#     Integer containing the device mDNIe color blindness feature flag.
#     It can be checked in the following ways:
#       - (API 34 and below) `WEAKNESS_SOLUTION_FUNCTION` value in the `com.samsung.android.hardware.display.SemMdnieManagerService` class inside `services.jar`
#       - (API 35 and above) `A11Y_COLOR_BOOL_SUPPORT_DMC_COLORWEAKNESS` value in the `android.view.accessibility.A11yRune` class inside `framework.jar`
#
#   [SOURCE/TARGET]_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS
#     Integer containing the device auto brightness type.
#     It can be checked in the following ways:
#       - `AUTO_BRIGHTNESS_TYPE` value in the `com.android.server.power.PowerManagerUtil` class inside `services.jar`
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" value in floating_feature.xml
#
#   [SOURCE/TARGET]_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE
#     Integer containing the device default refresh rate.
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_LCD_CONFIG_HFR_MODE
#     Integer containing the device variable refresh rate type.
#     It can be checked in the following ways:
#       - `LCD_CONFIG_HFR_MODE` value in the `com.samsung.android.hardware.secinputdev.SemInputFeatures` class inside `secinputdev-service.jar`
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_MODE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE
#     String containing the device available refresh rate profiles.
#     Defaults to "none" for devices without VRR.
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS
#     String containing the device refresh rate normal speed.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" value in floating_feature.xml
#
#   [SOURCE/TARGET]_LCD_CONFIG_SEAMLESS_BRT
#     String containing the device low/high brightness thresholds for VRR.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `configBrt` value in the `com.samsung.android.hardware.display.RefreshRateConfig` class inside `framework.jar`
#
#   [SOURCE/TARGET]_LCD_CONFIG_SEAMLESS_LUX
#     String containing the device low/high ambient lux thresholds for VRR.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `configLux` value in the `com.samsung.android.hardware.display.RefreshRateConfig` class inside `framework.jar`
#
#   [SOURCE/TARGET]_LCD_SUPPORT_MDNIE_HW
#     Boolean which describes whether the device supports hardware mDNIe.
#     It can be checked in the following ways:
#       - `A11Y_COLOR_BOOL_SUPPORT_MDNIE_HW` value in the `android.view.accessibility.A11yRune` class inside `framework.jar`
#
#   [SOURCE/TARGET]_RIL_FEATURES
#     String containing the device RIL feature string.
#     Defaults to "none".
#     It can be checked in the following ways:
#     - `RIL_FEATURES` value in the `com.android.internal.telephony.TelephonyFeatures` class inside `framework.jar`
#
#   [SOURCE/TARGET]_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT
#     Integer containing the device multi SIM tray count.
#
#   [SOURCE/TARGET]_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG
#     Boolean which describes whether the device SIM tray has waterproof protection.
#
#   [SOURCE/TARGET]_SECURITY_CONFIG_ESE_CHIP_VENDOR
#     String containing the device eSE chip vendor.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `chipVendor` value in the `com.android.server.SemService` class inside `framework.jar`
#       - `chipVendor` value in the `com.samsung.android.service.SemService.SemServiceManager` class inside `framework.jar`
#       - `chipVendor` value in the `com.android.se.internal.UtilExtension` class inside `SecureElement.apk`
#
#   [SOURCE/TARGET]_SECURITY_CONFIG_ESE_COS_NAME
#     String containing the device eSE cOS name.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `cosName` value in the `com.android.server.SemService` class inside `framework.jar`
#       - `cosName` value in the `com.samsung.android.service.SemService.SemServiceManager` class inside `framework.jar`
#       - `mEseCosName` value in the `com.android.se.internal.UtilExtension` class inside `SecureElement.apk`
#
#   [SOURCE/TARGET]_WLAN_CONFIG_CONNECTION_PERSONALIZATION
#     Integer containing the device Connection Personalizer feature flag.
#
#   [SOURCE/TARGET]_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD
#     Integer containing the device CPU C-State boost threshold.
#
#   [SOURCE/TARGET]_WLAN_CONFIG_CUSTOM_BACKOFF
#     String containing the device backoff config for Wi-Fi coex channel avoidance.
#
#   [SOURCE/TARGET]_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD
#     Integer containing the device Wi-Fi affinity boost threshold.
#
#   [SOURCE/TARGET]_WLAN_CONFIG_DYNAMIC_SWITCH
#     Integer containing the device dynamic switch feature flag.
#
#   [SOURCE/TARGET]_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD
#     Integer containing the device L1ss boost threshold.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_80211AX
#     Boolean which describes whether the device supports the Wi-Fi 6 standard.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_80211AX_6GHZ
#     Boolean which describes whether the device supports the Wi-Fi 6E standard.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_APE_SERVICE
#     Boolean which describes whether the device supports the "Realtime Data Priority Mode" feature.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_LOWLATENCY
#     Boolean which describes whether the device supports low latency Wi-Fi.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MBO
#     Boolean which describes whether the device supports the Wi-Fi Agile Multiband standard.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY
#     Boolean which describes whether the device should enable the 5Ghz Mobile Hotspot band depending the country code.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_6G
#     Boolean which describes whether the device supports Wi-Fi 6E Mobile Hotspot.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_DUALAP
#     Boolean which describes whether the device supports the Mobile Hotspot dual band feature.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_OWE
#     Boolean which describes whether the device supports the OWE standard.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE
#     Boolean which describes whether the device supports the Mobile Hotspot "Power saving mode" feature.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC
#     Boolean which describes whether the device supports the Mobile Hotspot "Prioritize real-time traffic" feature.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY
#     Boolean which describes whether the device supports DBS.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE
#     Boolean which describes whether the device supports Wi-Fi Sharing Lite.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS
#     Boolean which describes whether the device supports the "Allow individual apps to switch" feature.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_TWT_CONTROL
#     Boolean which describes whether the device supports TWT.
#
#   [SOURCE/TARGET]_WLAN_SUPPORT_WIFI_TO_CELLULAR
#     Boolean which describes whether the device supports Wi-Fi to Cellular.
{
    echo "# Automatically generated by scripts/internal/gen_config_file.sh"
    echo "ROM_IS_OFFICIAL=\"$(IS_UNICA_CERT_AVAILABLE)\""
    GET_BUILD_VAR "ROM_VERSION"
    GET_BUILD_VAR "ROM_BUILD_TIMESTAMP" "$(date +%s)"
    GET_BUILD_VAR "SOURCE_FIRMWARE"
    if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        echo "SOURCE_EXTRA_FIRMWARES=\"$(IFS=":"; printf '%s' "${SOURCE_EXTRA_FIRMWARES[*]}")\""
    else
        echo "SOURCE_EXTRA_FIRMWARES=\"\""
    fi
    GET_BUILD_VAR "SOURCE_PLATFORM_SDK_VERSION"
    GET_BUILD_VAR "SOURCE_PRODUCT_SHIPPING_API_LEVEL"
    GET_BUILD_VAR "SOURCE_BOARD_API_LEVEL"
    GET_BUILD_VAR "TARGET_NAME"
    GET_BUILD_VAR "TARGET_CODENAME"
    GET_BUILD_VAR "TARGET_PLATFORM" "none"
    if [ "${#TARGET_ASSERT_MODEL[@]}" -ge 1 ]; then
        echo "TARGET_ASSERT_MODEL=\"$(IFS=":"; printf '%s' "${TARGET_ASSERT_MODEL[*]}")\""
    else
        echo "TARGET_ASSERT_MODEL=\"\""
    fi
    GET_BUILD_VAR "TARGET_FIRMWARE"
    if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        echo "TARGET_EXTRA_FIRMWARES=\"$(IFS=":"; printf '%s' "${TARGET_EXTRA_FIRMWARES[*]}")\""
    else
        echo "TARGET_EXTRA_FIRMWARES=\"\""
    fi
    GET_BUILD_VAR "TARGET_PLATFORM_SDK_VERSION"
    GET_BUILD_VAR "TARGET_PRODUCT_SHIPPING_API_LEVEL"
    GET_BUILD_VAR "TARGET_BOARD_API_LEVEL"
    GET_BUILD_VAR "TARGET_DISABLE_AVB_SIGNING" "false"
    GET_BUILD_VAR "TARGET_INCLUDE_PATCHED_VBMETA" "false"
    GET_BUILD_VAR "TARGET_KEEP_ORIGINAL_SIGN" "false"
    GET_BUILD_VAR "TARGET_BOOT_PARTITION_SIZE" "none"
    GET_BUILD_VAR "TARGET_DTBO_PARTITION_SIZE" "none"
    GET_BUILD_VAR "TARGET_INIT_BOOT_PARTITION_SIZE" "none"
    GET_BUILD_VAR "TARGET_VENDOR_BOOT_PARTITION_SIZE" "none"
    GET_BUILD_VAR "TARGET_SUPER_PARTITION_SIZE"
    GET_BUILD_VAR "SOURCE_SUPER_GROUP_NAME"
    GET_BUILD_VAR "TARGET_SUPER_GROUP_NAME" "$SOURCE_SUPER_GROUP_NAME"
    GET_BUILD_VAR "TARGET_$(tr "[:lower:]" "[:upper:]" <<< "${TARGET_SUPER_GROUP_NAME:-$SOURCE_SUPER_GROUP_NAME}")_SIZE"
    GET_BUILD_VAR "TARGET_OS_SINGLE_SYSTEM_IMAGE"
    GET_BUILD_VAR "TARGET_OS_FILE_SYSTEM_TYPE" "erofs"
    GET_BUILD_VAR "TARGET_OS_BUILD_SYSTEM_EXT_PARTITION"
    GET_BUILD_VAR "TARGET_OS_BOOT_DEVICE_PATH" "/dev/block/bootdevice/by-name"
    GET_BUILD_VAR "SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" "none"
    GET_BUILD_VAR "TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" "none"
    GET_BUILD_VAR "SOURCE_AUDIO_SUPPORT_ACH_RINGTONE"
    GET_BUILD_VAR "TARGET_AUDIO_SUPPORT_ACH_RINGTONE"
    GET_BUILD_VAR "SOURCE_AUDIO_SUPPORT_DUAL_SPEAKER"
    GET_BUILD_VAR "TARGET_AUDIO_SUPPORT_DUAL_SPEAKER"
    GET_BUILD_VAR "SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION"
    GET_BUILD_VAR "TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION"
    GET_BUILD_VAR "SOURCE_CAMERA_SUPPORT_CAMERAX_EXTENSION"
    GET_BUILD_VAR "TARGET_CAMERA_SUPPORT_CAMERAX_EXTENSION"
    GET_BUILD_VAR "SOURCE_CAMERA_SUPPORT_CUTOUT_PROTECTION"
    GET_BUILD_VAR "TARGET_CAMERA_SUPPORT_CUTOUT_PROTECTION"
    GET_BUILD_VAR "SOURCE_CAMERA_SUPPORT_MASS_APP_FLAVOR"
    GET_BUILD_VAR "TARGET_CAMERA_SUPPORT_MASS_APP_FLAVOR"
    GET_BUILD_VAR "SOURCE_CAMERA_SUPPORT_SDK_SERVICE"
    GET_BUILD_VAR "TARGET_CAMERA_SUPPORT_SDK_SERVICE"
    GET_BUILD_VAR "SOURCE_COMMON_CONFIG_MDNIE_MODE"
    GET_BUILD_VAR "TARGET_COMMON_CONFIG_MDNIE_MODE"
    GET_BUILD_VAR "SOURCE_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL"
    GET_BUILD_VAR "TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL"
    GET_BUILD_VAR "SOURCE_COMMON_SUPPORT_EMBEDDED_SIM"
    GET_BUILD_VAR "TARGET_COMMON_SUPPORT_EMBEDDED_SIM"
    GET_BUILD_VAR "SOURCE_COMMON_SUPPORT_HDR_EFFECT" "$(test "$((SOURCE_COMMON_CONFIG_MDNIE_MODE & 4))" != "0" && echo "true" || echo "false")"
    GET_BUILD_VAR "TARGET_COMMON_SUPPORT_HDR_EFFECT" "$(test "$((TARGET_COMMON_CONFIG_MDNIE_MODE & 4))" != "0" && echo "true" || echo "false")"
    GET_BUILD_VAR "SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME"
    GET_BUILD_VAR "TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME"
    GET_BUILD_VAR "SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME"
    GET_BUILD_VAR "TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME"
    GET_BUILD_VAR "SOURCE_FINGERPRINT_CONFIG_SENSOR"
    GET_BUILD_VAR "TARGET_FINGERPRINT_CONFIG_SENSOR"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_HFR_MODE"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_HFR_MODE"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" "$(test "$SOURCE_LCD_CONFIG_HFR_MODE" -gt "0" && echo "" || echo "none")"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" "$(test "$TARGET_LCD_CONFIG_HFR_MODE" -gt "0" && echo "" || echo "none")"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" "none"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" "none"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_SEAMLESS_BRT" "none"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_SEAMLESS_BRT" "none"
    GET_BUILD_VAR "SOURCE_LCD_CONFIG_SEAMLESS_LUX" "none"
    GET_BUILD_VAR "TARGET_LCD_CONFIG_SEAMLESS_LUX" "none"
    GET_BUILD_VAR "SOURCE_LCD_SUPPORT_MDNIE_HW"
    GET_BUILD_VAR "TARGET_LCD_SUPPORT_MDNIE_HW"
    GET_BUILD_VAR "SOURCE_RIL_FEATURES" "none"
    GET_BUILD_VAR "TARGET_RIL_FEATURES" "none"
    GET_BUILD_VAR "SOURCE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT"
    GET_BUILD_VAR "TARGET_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT"
    GET_BUILD_VAR "SOURCE_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG"
    GET_BUILD_VAR "TARGET_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG"
    GET_BUILD_VAR "SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" "none"
    GET_BUILD_VAR "TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" "none"
    GET_BUILD_VAR "SOURCE_SECURITY_CONFIG_ESE_COS_NAME" "none"
    GET_BUILD_VAR "TARGET_SECURITY_CONFIG_ESE_COS_NAME" "none"
    GET_BUILD_VAR "SOURCE_WLAN_CONFIG_CONNECTION_PERSONALIZATION"
    GET_BUILD_VAR "TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION"
    GET_BUILD_VAR "SOURCE_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD"
    GET_BUILD_VAR "TARGET_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD"
    GET_BUILD_VAR "SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" "none"
    GET_BUILD_VAR "TARGET_WLAN_CONFIG_CUSTOM_BACKOFF" "none"
    GET_BUILD_VAR "SOURCE_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD"
    GET_BUILD_VAR "TARGET_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD"
    GET_BUILD_VAR "SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH"
    GET_BUILD_VAR "TARGET_WLAN_CONFIG_DYNAMIC_SWITCH"
    GET_BUILD_VAR "SOURCE_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD"
    GET_BUILD_VAR "TARGET_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_80211AX"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_80211AX"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_80211AX_6GHZ"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_80211AX_6GHZ"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_APE_SERVICE"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_APE_SERVICE"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_LOWLATENCY"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_LOWLATENCY"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MBO"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MBO"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_6G"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_6G"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_DUALAP"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_OWE"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_OWE"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_TWT_CONTROL"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_TWT_CONTROL"
    GET_BUILD_VAR "SOURCE_WLAN_SUPPORT_WIFI_TO_CELLULAR"
    GET_BUILD_VAR "TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR"
} > "$OUT_DIR/config.sh"

exit 0
