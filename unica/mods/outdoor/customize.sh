# shellcheck shell=bash
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/display/controller/SecOutDoorModePreferenceController.smali" "return" \
    'isAvailable()Z' \
    'true'
