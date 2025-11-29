# SEC_PRODUCT_FEATURE_SECURITY_CONFIG_ESE_CHIP_VENDOR
# SEC_PRODUCT_FEATURE_SECURITY_CONFIG_ESE_COS_NAME
if [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" == "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" ]] && \
    [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" == "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" ]]; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    return 0
fi

# [
LOG_MISSING_PATCHES()
{
    local MESSAGE="Missing SPF patches for condition ($1: [${!1}], $2: [${!2}])"

    if $DEBUG; then
        LOGW "$MESSAGE"
    else
        ABORT "${MESSAGE}. Aborting"
    fi
}
# ]

if [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" == "NXP" ]] && [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" == "JCOP6.2U" ]] && \
        [[ "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" == "none" ]] && [[ "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" == "none" ]]; then
    APPLY_PATCH "system" "system/app/SecureElement/SecureElement.apk" \
        "$MODPATH/ese/SecureElement.apk/0001-Disable-eSE-support.patch"
    DELETE_FROM_WORK_DIR "system" "system/bin/sem_daemon"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/sem.rc" 2>&1 | sed "/File not found/d"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/sem_early.rc" 2>&1 | sed "/File not found/d"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.ese.xml"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.sem.factoryapp.xml"
    APPLY_PATCH "system" "system/framework/framework.jar" "$MODPATH/ese/framework.jar/0001-Disable-SemService.patch"
    EVAL "cp -a \"$MODPATH/framework.jar/SemService.smali\" \"$APKTOOL_DIR/system/framework/framework.jar/smali_classes6/com/android/server/SemService.smali\""
    APPLY_PATCH "system" "system/framework/services.jar" "$MODPATH/ese/services.jar/0001-Disable-SemService.patch"
    if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" != "mssi" ]]; then
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "a73xqxx" || echo "a54xnsxx")" \
            "system" "system/lib/libsec_semRil.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "a73xqxx" || echo "a54xnsxx")" \
            "system" "system/lib/libtlc_blockchain_keystore.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "a73xqxx" || echo "a54xnsxx")" \
            "system" "system/lib/libtlc_payment_spay.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "a73xqxx" || echo "a54xnsxx")" \
            "system" "system/lib64/libsec_semRil.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "a73xqxx" || echo "a54xnsxx")" \
            "system" "system/lib64/libtlc_blockchain_keystore.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "a73xqxx" || echo "a54xnsxx")" \
            "system" "system/lib64/libtlc_payment_spay.so" 0 0 644 "u:object_r:system_lib_file:s0"
    fi
    DELETE_FROM_WORK_DIR "system" "system/priv-app/SEMFactoryApp"
    DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungSeAgent"
elif [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" != "none" ]] && [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" != "none" ]]; then
    if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "mssi" ]]; then
        ABORT "\"mssi\" system image does not support targets with eSE. Aborting"
    fi

    if [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" != "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" ]]; then
        SMALI_PATCH "system" "system/app/SecureElement/SecureElement.apk" \
            "smali/com/android/se/internal/UtilExtension.smali" "replace" \
            "<clinit>()V" \
            "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" \
            "${TARGET_SECURITY_CONFIG_ESE_COS_NAME//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" != "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" ]]; then
        SMALI_PATCH "system" "system/app/SecureElement/SecureElement.apk" \
            "smali/com/android/se/internal/UtilExtension.smali" "replace" \
            "supportEse(Landroid/content/Context;)Z" \
            "eSE_COS: $SOURCE_SECURITY_CONFIG_ESE_COS_NAME" \
            "eSE_COS: ${TARGET_SECURITY_CONFIG_ESE_COS_NAME//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" != "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" ]]; then
        SMALI_PATCH "system" "system/app/SecureElement/SecureElement.apk" \
            "smali/com/android/se/internal/UtilExtension.smali" "replace" \
            "supportEse(Landroid/content/Context;)Z" \
            "eSE_Vendor: $SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" \
            "eSE_Vendor: ${TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" != "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" ]]; then
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "smali_classes6/com/android/server/SemService.smali" "replaceall" \
            "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" \
            "${TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" != "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" ]]; then
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "smali_classes6/com/android/server/SemService.smali" "replaceall" \
            "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" \
            "${TARGET_SECURITY_CONFIG_ESE_COS_NAME//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" != "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" ]]; then
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "smali_classes6/com/samsung/android/service/SemService/SemServiceManager.smali" "replaceall" \
            "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" \
            "${TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" != "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" ]]; then
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "smali_classes6/com/samsung/android/service/SemService/SemServiceManager.smali" "replaceall" \
            "$SOURCE_SECURITY_CONFIG_ESE_COS_NAME" \
            "${TARGET_SECURITY_CONFIG_ESE_COS_NAME//none/}"
    fi
    if [[ "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" != "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" ]]; then
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/samsung/ucm/ucmservice/CredentialManagerService.smali" "replaceall" \
            "$SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" \
            "${TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR//none/}"
    fi
else
    LOG_MISSING_PATCHES "SOURCE_SECURITY_CONFIG_ESE_CHIP_VENDOR" "TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" || true
    LOG_MISSING_PATCHES "SOURCE_SECURITY_CONFIG_ESE_COS_NAME" "TARGET_SECURITY_CONFIG_ESE_COS_NAME"
fi

unset -f LOG_MISSING_PATCHES
