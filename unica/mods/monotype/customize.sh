# shellcheck shell=bash
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali" "return" \
    'isInvalidFont(Landroid/content/Context;Ljava/lang/String;)Z' \
    'false'
