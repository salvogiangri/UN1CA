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
fi

if [ ! -f "$SRC_DIR/unica/configs/$TARGET_SINGLE_SYSTEM_IMAGE.sh" ]; then
    LOGE "\"$TARGET_SINGLE_SYSTEM_IMAGE\" is not a valid system image"
    exit 1
else
    source "$SRC_DIR/unica/configs/$TARGET_SINGLE_SYSTEM_IMAGE.sh" || exit 1
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
#   ROM_CODENAME
#     String containing the release codename, it is set in unica/configs/version.sh.
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
#   [SOURCE/TARGET]_API_LEVEL
#     Integer containing the SDK API level of the device firmware, it must match the `ro.build.version.sdk` prop.
#
#   [SOURCE/TARGET]_PRODUCT_FIRST_API_LEVEL
#     Integer containing the SDK API level that the device is initially launched with,
#     it must match the `ro.product.first_api_level` prop.
#
#   [SOURCE/TARGET]_VENDOR_API_LEVEL
#     Integer containing the vendor API level, it must match the `ro.board.api_level` prop.
#
#   TARGET_ASSERT_MODEL
#     If defined, the zip package will use the provided model numbers with the value in the `ro.boot.em.model` prop
#     to ensure if it is compatible with the device it is currently being installed in, by default TARGET_CODENAME
#     is checked instead.
#
#     Example:
#       `TARGET_ASSERT_MODEL=("SM-A528B" "SM-A528N")`
#
#   TARGET_SINGLE_SYSTEM_IMAGE
#     String containing the target device SSI, it must match the `ro.build.product` prop.
#     Currently, only "qssi" is supported.
#
#   TARGET_OS_FILE_SYSTEM
#     String containing the target device firmware file system.
#     Using a value different than stock will require patching the device fstab file in vendor and kernel ramdisk.
#
#   TARGET_BOOT_DEVICE_PATH
#     String containing the path to the target device folder containing its block devices.
#     Defaults to "/dev/block/bootdevice/by-name".
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
#     Notice this must be bigger than TARGET_SUPER_GROUP_SIZE.
#
#   [SOURCE/TARGET]_SUPER_GROUP_NAME
#     String containing the super partition group name the device uses.
#     When TARGET_SUPER_GROUP_NAME is not set, the value in SOURCE_SUPER_GROUP_NAME is used by default.
#
#   TARGET_SUPER_GROUP_SIZE
#     Integer containing the size in bytes of the target device super group size, which can be checked using the lpdump tool.
#     Notice this must be smaller than TARGET_SUPER_PARTITION_SIZE.
#
#   [SOURCE/TARGET]_HAS_SYSTEM_EXT
#     Boolean which describes whether the device has a separate system_ext partition.
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
#   [SOURCE/TARGET]_AUTO_BRIGHTNESS_TYPE
#     Integer containing the device auto brightness type.
#     It can be checked in the following ways:
#       - `AUTO_BRIGHTNESS_TYPE` value in the `com.android.server.power.PowerManagerUtil` class inside `services.jar`
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" value in floating_feature.xml
#
#   [SOURCE/TARGET]_DVFS_CONFIG_NAME
#     String containing the DVFS config file name used by SDHMS.
#     It can be checked in the following ways:
#       - `DVFS_FILENAME` value in the `com.android.server.ssrm.Feature` class inside `ssrm.jar`
#
#   [SOURCE/TARGET]_ESE_CHIP_VENDOR
#     String containing the device eSE chip vendor.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `chipVendor` value in the `com.android.server.SemService` class inside `framework.jar`
#       - `chipVendor` value in the `com.android.se.internal.UtilExtension` class inside `SecureElement.apk`
#
#   [SOURCE/TARGET]_ESE_COS_NAME
#     String containing the device eSE COS name.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `cosName` value in the `com.android.server.SemService` class inside `framework.jar`
#       - `cosName` value in the `com.samsung.android.service.SemService` class inside `framework.jar`
#       - `mEseCosName` value in the `com.android.se.internal.UtilExtension` class inside `SecureElement.apk`
#
#   [SOURCE/TARGET]_FP_SENSOR_CONFIG
#     String containing the fingerprint sensor feature string.
#     It can be checked in the following ways:
#       - `mConfig` value in the `com.samsung.android.bio.fingerprint.SemFingerprintManager$Characteristic` class inside `framework.jar`
#
#   [SOURCE/TARGET]_HAS_HW_MDNIE
#     Boolean which describes whether the device supports hardware mDNIe.
#     It can be checked in the following ways:
#       - `A11Y_COLOR_BOOL_SUPPORT_MDNIE_HW` value in the `android.view.accessibility.A11yRune` class inside `framework.jar`
#
#   [SOURCE/TARGET]_HAS_MASS_CAMERA_APP
#     Boolean which describes whether the device ships the mass Samsung Camera app variant.
#     It can be checked in the following ways:
#       - `AndroidManifest.xml` of `SamsungCamera.apk` has `hal3_mass-phone-release` value
#
#   [SOURCE/TARGET]_HAS_QHD_DISPLAY
#     Boolean which describes whether the device has a WQHD(+) display.
#     It can be checked in the following ways:
#       - `FW_DYNAMIC_RESOLUTION_CONTROL` in the `com.samsung.android.rune.CoreRune` class inside `framework.jar` is set to true
#       - "SEC_FLOATING_FEATURE_COMMON_CONFIG_DYN_RESOLUTION_CONTROL" in floating_feature.xml is set
#
#   [SOURCE/TARGET]_HFR_MODE
#     Integer containing the device variable refresh rate type.
#     It can be checked in the following ways:
#       - `LCD_CONFIG_HFR_MODE` value in the `com.samsung.android.hardware.secinputdev.SemInputFeatures` class inside `secinputdev-service.jar`
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_MODE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_HFR_SUPPORTED_REFRESH_RATE
#     String containing the device available refresh rate profiles.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_HFR_DEFAULT_REFRESH_RATE
#     Integer containing the device default refresh rate.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_HFR_SEAMLESS_BRT
#     String containing the device low/high brightness thresholds for VRR.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `configBrt` value in the `com.samsung.android.hardware.display.RefreshRateConfig` class inside `framework.jar`
#
#   [SOURCE/TARGET]_HFR_SEAMLESS_LUX
#     String containing the device low/high ambient lux thresholds for VRR.
#     Defaults to "none".
#     It can be checked in the following ways:
#       - `configLux` value in the `com.samsung.android.hardware.display.RefreshRateConfig` class inside `framework.jar`
#
#   [SOURCE/TARGET]_IS_ESIM_SUPPORTED
#     Boolean which describes whether the device has eSIM support.
#     It can be checked in the following ways:
#       - "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" in floating_feature.xml is set
#
#   [SOURCE/TARGET]_MDNIE_SUPPORTED_MODES
#     Integer containing the device mDNIe feature bit flag.
#     It can be checked in the following ways:
#       - `MDNIE_SUPPORT_FUNCTION` value in the `com.samsung.android.hardware.display.SemMdnieManagerService` class inside `services.jar`
#       - "SEC_FLOATING_FEATURE_COMMON_CONFIG_MDNIE_MODE" value in floating_feature.xml
#
#   [SOURCE/TARGET]_MDNIE_WEAKNESS_SOLUTION_FUNCTION
#     Integer containing the device mDNIe color blindness feature flag.
#     It can be checked in the following ways:
#       - `WEAKNESS_SOLUTION_FUNCTION` value in the `com.samsung.android.hardware.display.SemMdnieManagerService` class inside `services.jar`
#
#   [SOURCE/TARGET]_MDNIE_SUPPORT_HDR_EFFECT
#     Boolean which describes whether the device supports the "Video brightness" feature.
#     Defaults to true if MDNIE_SUPPORTED_MODES contains the "mSupportContentModeVideoEnhance" bit (1 << 2).
#     It can be checked in the following ways:
#       - `com.samsung.android.settings.usefulfeature.videoenhancer.VideoEnhancerPreferenceController.getAvailabilityStatus()`
#         method inside `SecSettings.apk` is not UNSUPPORTED_ON_DEVICE (3)
#       - "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT" in floating_feature.xml is set to "TRUE"
#
#   [SOURCE/TARGET]_MULTI_MIC_MANAGER_VERSION
#     Integer containing the device SemMultiMicManager "version".
#     It can be checked in the following ways:
#       - `version` parameter in the `com.samsung.android.camera.mic.SemMultiMicManager.isSupported()` method inside `framework.jar`
#
#   [SOURCE/TARGET]_SSRM_CONFIG_NAME
#     String containing the SSRM config file name used by SDHMS.
#     It can be checked in the following ways:
#       - `SSRM_FILENAME` value in the `com.android.server.ssrm.Feature` class inside `ssrm.jar`
#       - "SEC_FLOATING_FEATURE_SYSTEM_CONFIG_SIOP_POLICY_FILENAME" value in floating_feature.xml
#
#   [SOURCE/TARGET]_SUPPORT_CUTOUT_PROTECTION
#     Boolean which describes whether the device supports the camera cutout protection feature.
#     It can be checked in the following ways:
#       - "config_enableDisplayCutoutProtection" in "res/values/bools.xml" inside `SystemUI.apk` is set to "true"
{
    echo "# Automatically generated by scripts/internal/gen_config_file.sh"
    echo "ROM_IS_OFFICIAL=\"$(IS_UNICA_CERT_AVAILABLE)\""
    GET_BUILD_VAR "ROM_VERSION"
    GET_BUILD_VAR "ROM_CODENAME"
    GET_BUILD_VAR "ROM_BUILD_TIMESTAMP" "$(date +%s)"
    GET_BUILD_VAR "SOURCE_FIRMWARE"
    if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        echo "SOURCE_EXTRA_FIRMWARES=\"$(IFS=":"; printf '%s' "${SOURCE_EXTRA_FIRMWARES[*]}")\""
    else
        echo "SOURCE_EXTRA_FIRMWARES=\"\""
    fi
    GET_BUILD_VAR "SOURCE_API_LEVEL"
    GET_BUILD_VAR "SOURCE_PRODUCT_FIRST_API_LEVEL"
    GET_BUILD_VAR "SOURCE_VENDOR_API_LEVEL"
    GET_BUILD_VAR "TARGET_NAME"
    GET_BUILD_VAR "TARGET_CODENAME"
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
    GET_BUILD_VAR "TARGET_API_LEVEL"
    GET_BUILD_VAR "TARGET_PRODUCT_FIRST_API_LEVEL"
    GET_BUILD_VAR "TARGET_VENDOR_API_LEVEL"
    GET_BUILD_VAR "TARGET_SINGLE_SYSTEM_IMAGE"
    GET_BUILD_VAR "TARGET_OS_FILE_SYSTEM"
    GET_BUILD_VAR "TARGET_BOOT_DEVICE_PATH" "/dev/block/bootdevice/by-name"
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
    GET_BUILD_VAR "TARGET_SUPER_GROUP_SIZE"
    GET_BUILD_VAR "SOURCE_HAS_SYSTEM_EXT"
    GET_BUILD_VAR "TARGET_HAS_SYSTEM_EXT"
    GET_BUILD_VAR "SOURCE_AUDIO_SUPPORT_ACH_RINGTONE"
    GET_BUILD_VAR "TARGET_AUDIO_SUPPORT_ACH_RINGTONE"
    GET_BUILD_VAR "SOURCE_AUDIO_SUPPORT_DUAL_SPEAKER"
    GET_BUILD_VAR "TARGET_AUDIO_SUPPORT_DUAL_SPEAKER"
    GET_BUILD_VAR "SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION"
    GET_BUILD_VAR "TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION"
    GET_BUILD_VAR "SOURCE_AUTO_BRIGHTNESS_TYPE"
    GET_BUILD_VAR "TARGET_AUTO_BRIGHTNESS_TYPE"
    GET_BUILD_VAR "SOURCE_DVFS_CONFIG_NAME"
    GET_BUILD_VAR "TARGET_DVFS_CONFIG_NAME"
    GET_BUILD_VAR "SOURCE_ESE_CHIP_VENDOR" "none"
    GET_BUILD_VAR "TARGET_ESE_CHIP_VENDOR" "none"
    GET_BUILD_VAR "SOURCE_ESE_COS_NAME" "none"
    GET_BUILD_VAR "TARGET_ESE_COS_NAME" "none"
    GET_BUILD_VAR "SOURCE_FP_SENSOR_CONFIG"
    GET_BUILD_VAR "TARGET_FP_SENSOR_CONFIG"
    GET_BUILD_VAR "SOURCE_HAS_HW_MDNIE"
    GET_BUILD_VAR "TARGET_HAS_HW_MDNIE"
    GET_BUILD_VAR "SOURCE_HAS_MASS_CAMERA_APP"
    GET_BUILD_VAR "TARGET_HAS_MASS_CAMERA_APP"
    GET_BUILD_VAR "SOURCE_HAS_QHD_DISPLAY"
    GET_BUILD_VAR "TARGET_HAS_QHD_DISPLAY"
    GET_BUILD_VAR "SOURCE_HFR_MODE"
    GET_BUILD_VAR "TARGET_HFR_MODE"
    GET_BUILD_VAR "SOURCE_HFR_SUPPORTED_REFRESH_RATE" "none"
    GET_BUILD_VAR "TARGET_HFR_SUPPORTED_REFRESH_RATE" "none"
    GET_BUILD_VAR "SOURCE_HFR_DEFAULT_REFRESH_RATE" "none"
    GET_BUILD_VAR "TARGET_HFR_DEFAULT_REFRESH_RATE" "none"
    GET_BUILD_VAR "SOURCE_HFR_SEAMLESS_BRT" "none"
    GET_BUILD_VAR "TARGET_HFR_SEAMLESS_BRT" "none"
    GET_BUILD_VAR "SOURCE_HFR_SEAMLESS_LUX" "none"
    GET_BUILD_VAR "TARGET_HFR_SEAMLESS_LUX" "none"
    GET_BUILD_VAR "SOURCE_IS_ESIM_SUPPORTED"
    GET_BUILD_VAR "TARGET_IS_ESIM_SUPPORTED"
    GET_BUILD_VAR "SOURCE_MDNIE_SUPPORTED_MODES"
    GET_BUILD_VAR "TARGET_MDNIE_SUPPORTED_MODES"
    GET_BUILD_VAR "SOURCE_MDNIE_WEAKNESS_SOLUTION_FUNCTION"
    GET_BUILD_VAR "TARGET_MDNIE_WEAKNESS_SOLUTION_FUNCTION"
    GET_BUILD_VAR "SOURCE_MDNIE_SUPPORT_HDR_EFFECT" "$(test "$((SOURCE_MDNIE_SUPPORTED_MODES & 4))" != "0" && echo "true" || echo "false")"
    GET_BUILD_VAR "TARGET_MDNIE_SUPPORT_HDR_EFFECT" "$(test "$((TARGET_MDNIE_SUPPORTED_MODES & 4))" != "0" && echo "true" || echo "false")"
    GET_BUILD_VAR "SOURCE_MULTI_MIC_MANAGER_VERSION"
    GET_BUILD_VAR "TARGET_MULTI_MIC_MANAGER_VERSION"
    GET_BUILD_VAR "SOURCE_SSRM_CONFIG_NAME"
    GET_BUILD_VAR "TARGET_SSRM_CONFIG_NAME"
    GET_BUILD_VAR "SOURCE_SUPPORT_CUTOUT_PROTECTION" "false"
    GET_BUILD_VAR "TARGET_SUPPORT_CUTOUT_PROTECTION" "false"
} > "$OUT_DIR/config.sh"

exit 0
