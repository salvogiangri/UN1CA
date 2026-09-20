# Disable app compaction
# Guard the patch as the source firmware might have this already disabled
LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch" &> /dev/null || true

# Disable FM Radio country restrictions
if [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_CHIP_VENDOR")" != "0" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_AVOID_REGION" --delete

    SMALI_PATCH "system" "system/framework/samsungfmradiolib.jar" \
        "smali/com/samsung/frameworks/fmradio/FMRadioImpl.smali" "return" \
        'isRadioNotSupportedInRegion()Z' \
        'false'
fi
