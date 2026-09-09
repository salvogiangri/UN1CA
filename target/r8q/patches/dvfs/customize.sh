SMALI_PATCH "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" \
    "smali/r1/c.smali" "replace" \
    '<clinit>()V' \
    'SM8350' \
    'SM8250'
