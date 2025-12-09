SKIPUNZIP=1
MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

# S24 FE OneUI 7 -> SoundBooster 2000
# S10 Series -> SoundBooster 1000
LOG_STEP_IN "- Replacing SoundBooster"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2000.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SAG_EQ_ver2000.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsoundboostereq_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1000.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing GameDriver"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-EX9820/GameDriver-EX9820.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/DevGPUDriver-EX9820/DevGPUDriver-EX9820.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Hotword"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
mkdir -p "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleExCORTEXM4"
mkdir -p "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleExCORTEXM4"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/priv-app/HotwordEnrollmentOKGoogleExCORTEXM4/HotwordEnrollmentOKGoogleExCORTEXM4.apk" "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleExCORTEXM4/HotwordEnrollmentOKGoogleExCORTEXM4.apk"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/priv-app/HotwordEnrollmentXGoogleExCORTEXM4/HotwordEnrollmentXGoogleExCORTEXM4.apk" "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleExCORTEXM4/HotwordEnrollmentXGoogleExCORTEXM4.apk"

SET_METADATA "product" "priv-app/HotwordEnrollmentOKGoogleExCORTEXM4" 0 0 755 "u:object_r:system_file:s0"
SET_METADATA "product" "priv-app/HotwordEnrollmentOKGoogleExCORTEXM4/HotwordEnrollmentOKGoogleExCORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
SET_METADATA "product" "priv-app/HotwordEnrollmentXGoogleExCORTEXM4" 0 0 755 "u:object_r:system_file:s0"
SET_METADATA "product" "priv-app/HotwordEnrollmentXGoogleExCORTEXM4/HotwordEnrollmentXGoogleExCORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding 32-Bit S21 (p3sxxx) WFD blobs"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/bin/remotedisplay" 0 2000 755 "u:object_r:remotedisplay_exec:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock NFC Case features"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.sview.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.nfc_authentication_cover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.clearcover.xml" 0 0 644 "u:object_r:system_file:s0"

if [[ "$TARGET_CODENAME" != "beyondx" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.flip.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.nfcledcover.xml" 0 0 644 "u:object_r:system_file:s0"
fi

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/LedBackCoverAppBeyond/LedBackCoverAppBeyond.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock cutout assets"
DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"
cp -a "$MODPATH/assets/"* "$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/assets/"
LOG_STEP_OUT
