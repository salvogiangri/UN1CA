LOG_STEP_IN "- Adding AppLock support"
ADD_TO_WORK_DIR "e1qzcx" "system" "system/app/AppLock/AppLock.apk"
ADD_TO_WORK_DIR "e1qzcx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.applock.xml"

SMALI_PATCH "system" "system/framework/framework.jar" "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replaceall" \
    "sput-boolean v1, Lcom/samsung/android/rune/CoreRune;->FW_SUPPORT_APPLOCK:Z" \
    "const/4 v1, 0x1\n\n    sput-boolean v1, Lcom/samsung/android/rune/CoreRune;->FW_SUPPORT_APPLOCK:Z"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk"\
    "smali_classes3/com/samsung/android/settings/usefulfeature/applock/AppLockPreferenceController.smali"\
    "return" "getAvailabilityStatus()I" "0"
LOG_STEP_OUT