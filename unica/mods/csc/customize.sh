# shellcheck shell=bash

# Enable Power off lock feature
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/globalactions/util/SystemPropertiesWrapper.smali" "return" \
    'isBrazilianCountryISO()Z' 'true'
SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
    "smali/com/android/systemui/bixby2/controller/DeviceController.smali" "return" \
    'isSupportPowerOffLock()Z' 'true'

# Hide Remote management tile in Settings app
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/homepage/TopLevelRemoteSupportPreferenceController.smali" "return" \
    'getAvailabilityStatus()I' '3'
