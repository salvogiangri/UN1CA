SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/locksettings/LockSettingsService.smali" "return" \
    'isEnablePrevCredential()Z' \
    'false'
