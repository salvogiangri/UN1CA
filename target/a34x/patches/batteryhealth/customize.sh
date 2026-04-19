# Forcefully enable Advanced Battery Information
# SM-A346B is known to support this feature so enable it

# https://cs.android.com/android/platform/superproject/+/android-latest-release:packages/apps/Settings/src/com/android/settings/core/BasePreferenceController.java
# 0x0 = SUPPORTED
# 0x3 = UNSUPPORTED ON DEVICE

# Always enable BatteryRegulatoryPreferenceController
# Normally this checks for auth support or if target is SM-A236B
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/deviceinfo/batteryinfo/BatteryRegulatoryPreferenceController.smali" "return" \
     "getAvailabilityStatus()I" \
     "0x0"

# Always enable SecBatteryFirstUseDataPreferenceController
# Normally this checks if target is NOT SM-A236B and for auth support
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/deviceinfo/batteryinfo/SecBatteryFirstUseDatePreferenceController.smali" "return" \
     "getAvailabilityStatus()I" \
     "0x0"
