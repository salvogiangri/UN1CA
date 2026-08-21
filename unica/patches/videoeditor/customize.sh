TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
TARGET_MULTIMEDIA_EDITOR_PLUGIN_PACKAGES="$(GET_FLOATING_FEATURE_CONFIG "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/floating_feature.xml" "SEC_FLOATING_FEATURE_COMMON_CONFIG_MULTIMEDIA_EDITOR_PLUGIN_PACKAGES")"

if [[ "$TARGET_MULTIMEDIA_EDITOR_PLUGIN_PACKAGES" != *"videoeditor"* ]]; then
    SMALI_PATCH "system" "system/app/VideoEditorLite_Dream_N/VideoEditorLite_Dream_N.apk" \
        "smali/com/sec/android/app/ve/specification/ChipSet.smali" "replace" \
        'fetchName()Ljava/util/ArrayList;' \
        'ro.soc.model' \
        'ro.unica.studio'
else
    LOG "\033[0;33m! Nothing to do\033[0m"
    unset TARGET_FIRMWARE_PATH TARGET_MULTIMEDIA_EDITOR_PLUGIN_PACKAGES
    return 0
fi

LOG "- Patching /system/system/etc/selinux/plat_property_contexts"
EVAL "echo \"ro.unica.studio        u:object_r:soc_prop:s0 exact string\" >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""

if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    SET_PROP "system" "ro.unica.studio" "sm7125"
elif [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
    SET_PROP "system" "ro.unica.studio" "exynos9611"
fi

unset TARGET_FIRMWARE_PATH TARGET_MULTIMEDIA_EDITOR_PLUGIN_PACKAGES
