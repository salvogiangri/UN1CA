SET_PROP_IF_DIFF "vendor" "ro.security.fips.ux" "Disabled"

if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    DONOR="a73xqxx"
elif [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
    DONOR="a54xnsxx"
else
    ABORT "Unknown SSI: $TARGET_OS_SINGLE_SYSTEM_IMAGE"
fi

DELETE_FROM_WORK_DIR "system" "system/app/BlockchainBasicKit"
ADD_TO_WORK_DIR "$DONOR" "system" "system/bin/installd" 0 2000 755 "u:object_r:installd_exec:s0"
ADD_TO_WORK_DIR "$DONOR" "system" "system/bin/vdc" 0 2000 755 "u:object_r:vdc_exec:s0"
ADD_TO_WORK_DIR "$DONOR" "system" "system/bin/vold" 0 2000 755 "u:object_r:vold_exec:s0"
# Support legacy sdFAT kernel drivers (pre-API 35)
# Check unica/patches/legacy/customize.sh for more info.
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ] && \
        grep -q "SDFAT" "$WORK_DIR/kernel/boot.img" && \
        ! grep -q "bogus directory:" "$WORK_DIR/kernel/boot.img"; then
    LOG_STEP_IN
    # ",time_offset=%d" -> "NUL"
    HEX_PATCH "$WORK_DIR/system/system/bin/vold" "2c74696d655f6f66667365743d2564" "000000000000000000000000000000"
    LOG_STEP_OUT
fi
DELETE_FROM_WORK_DIR "system" "system/bin/dualdard"
DELETE_FROM_WORK_DIR "system" "system/bin/sdp_cryptod"
DELETE_FROM_WORK_DIR "system" "system/etc/init/dualdard.rc"
DELETE_FROM_WORK_DIR "system" "system/etc/init/kpp.init.rc"
DELETE_FROM_WORK_DIR "system" "system/etc/init/kss.init.rc"
DELETE_FROM_WORK_DIR "system" "system/etc/init/sdp_cryptod.rc"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.hdmapp.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kgclient.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.kfbp.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.knnr.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.mpos.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.pushmanager.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.sandbox.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.zt.framework.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/signature-permissions-com.samsung.android.kgclient.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.coldwalletservice.xml"
DELETE_FROM_WORK_DIR "system" "system/lib/android.hardware.weaver@1.0.so"
DELETE_FROM_WORK_DIR "system" "system/lib/hidl_comm_ddar_client.so"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib/libandroid_servers.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/libdualdar.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libepm.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libhermes_cred.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libkeyutils.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libknox_filemanager.so"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib/libmdf.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/libmdfpp_req.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libpersona.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libsdp_crypto.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libsdp_kekm.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libsdp_sdk.so"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib/libsqlite.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.tlc.ddar@1.0.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/android.hardware.weaver@1.0.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/hidl_comm_ddar_client.so"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib64/libandroid_servers.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/libdualdar.so"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib64/libepm.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib64/libmdf.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/libmdfpp_req.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsdp_crypto.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsdp_kekm.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsdp_sdk.so"
ADD_TO_WORK_DIR "$DONOR" "system" "system/lib64/libsqlite.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.tlc.ddar@1.0.so"
DELETE_FROM_WORK_DIR "system" "system/priv-app/HdmApk"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxFrameBufferProvider"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxGuard"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxMposAgent"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxNeuralNetworkRuntime"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxPushManager"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxSandbox"
DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxZtFramework"

if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    ADD_TO_WORK_DIR "$DONOR" "system" "system/bin/apexd" 0 2000 755 "u:object_r:apexd_exec:s0"
    ADD_TO_WORK_DIR "$DONOR" "system" "system/bin/gsid" 0 2000 755 "u:object_r:gsid_exec:s0"
    ADD_TO_WORK_DIR "$DONOR" "system" "system/lib/service.incremental.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$DONOR" "system" "system/lib64/service.incremental.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    APPLY_PATCH "system" "system/framework/framework.jar" \
        "$MODPATH/vold/framework.jar/0001-Add-token-argument-in-unlockCeStorage.patch"
    APPLY_PATCH "system" "system/framework/services.jar" \
        "$MODPATH/vold/services.jar/0001-Add-token-argument-in-unlockCeStorage.patch"
fi

unset DONOR

DECODE_APK "system" "system/framework/services.jar"
SOURCE_FILE_ATTR="$(grep -F ".source" "$APKTOOL_DIR/system/framework/services.jar/smali/android/gsi/GsiProgress.smali")"
SOURCE_FILE_ATTR="${SOURCE_FILE_ATTR//\./\\\.}"
SOURCE_FILE_ATTR="${SOURCE_FILE_ATTR//\"/\\\"}"
SOURCE_FILE_ATTR="${SOURCE_FILE_ATTR//\//\\\/}"
LOG "- Replacing SourceFile attribute in /system/system/framework/services.jar"
find "$APKTOOL_DIR/system/framework/services.jar" -type f -name "*.smali" -print0 \
    | xargs -0 -I "{}" -P "$(nproc)" sed -i "s/^\.source.*/\.source \"SourceFile\"/g" "{}"
if [[ "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" != "$TARGET_PRODUCT_SHIPPING_API_LEVEL" ]]; then
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/knox/dar/ddar/ta/TAProxy.smali" "replace" \
        "updateServiceHolder(Z)V" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        > /dev/null
fi

# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_SDP
APPLY_PATCH "system" "system/framework/framework.jar" \
    "$MODPATH/sdp/framework.jar/0001-Nuke-Knox-SDP.patch"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/sdp/services.jar/0001-Nuke-Knox-SDP.patch"

# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_DUAL_DAR
APPLY_PATCH "system" "system/app/Traceur/Traceur.apk" \
    "$MODPATH/ddar/Traceur.apk/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/framework/framework.jar" \
    "$MODPATH/ddar/framework.jar/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/framework/framework.jar" \
    "$MODPATH/ddar/framework.jar/0002-Nuke-MDF.patch"
APPLY_PATCH "system" "system/framework/knoxsdk.jar" \
    "$MODPATH/ddar/knoxsdk.jar/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/ddar/services.jar/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/priv-app/DeviceDiagnostics/DeviceDiagnostics.apk" \
    "$MODPATH/ddar/DeviceDiagnostics.apk/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/priv-app/KnoxCore/KnoxCore.apk" \
    "$MODPATH/ddar/KnoxCore.apk/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/priv-app/ManagedProvisioning/ManagedProvisioning.apk" \
    "$MODPATH/ddar/ManagedProvisioning.apk/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$MODPATH/ddar/SecSettings.apk/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "$MODPATH/ddar/SecSettingsIntelligence.apk/0001-Nuke-Knox-DualDAR.patch"
APPLY_PATCH "system_ext" "priv-app/StorageManager/StorageManager.apk" \
    "$MODPATH/ddar/StorageManager.apk/0001-Nuke-Knox-DualDAR.patch"

# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_HDM
DECODE_APK "system" "system/framework/knoxsdk.jar"

HDM_VERSION="$(grep "const.* - .*\\w\"" "$APKTOOL_DIR/system/framework/knoxsdk.jar/smali/com/samsung/android/knox/hdm/HdmManager.smali" | tr -d "\"" | awk '{print $3}' -)"
HDM_POLICY_TYPE="$(grep "const.* - .*\\w\"" "$APKTOOL_DIR/system/framework/knoxsdk.jar/smali/com/samsung/android/knox/hdm/HdmManager.smali" | tr -d "\"" | awk '{print $5}' -)"

SMALI_PATCH "system" "system/app/Traceur/Traceur.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system" "system/app/Traceur/Traceur.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system" "system/app/Traceur/Traceur.apk" \
    "$MODPATH/hdm/Traceur.apk/0001-Nuke-Knox-HDM.patch"
SMALI_PATCH "system" "system/framework/knoxsdk.jar" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system" "system/framework/knoxsdk.jar" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system" "system/framework/knoxsdk.jar" \
    "$MODPATH/hdm/knoxsdk.jar/0001-Nuke-Knox-HDM.patch"
if [[ "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" != "$TARGET_PRODUCT_SHIPPING_API_LEVEL" ]]; then
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/enterprise/hdm/HdmSakManager.smali" "replace" \
        "isSupported(Landroid/content/Context;)Z" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        > /dev/null
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/enterprise/hdm/HdmVendorController.smali" "replace" \
        "<init>()V" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        > /dev/null
fi
# TODO nuke HdmVendorController.smali
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/hdm/services.jar/0001-Nuke-Knox-HDM.patch"
SMALI_PATCH "system" "system/priv-app/DeviceDiagnostics/DeviceDiagnostics.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/DeviceDiagnostics/DeviceDiagnostics.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system" "system/priv-app/DeviceDiagnostics/DeviceDiagnostics.apk" \
    "$MODPATH/hdm/DeviceDiagnostics.apk/0001-Nuke-Knox-HDM.patch"
SMALI_PATCH "system" "system/priv-app/ManagedProvisioning/ManagedProvisioning.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/ManagedProvisioning/ManagedProvisioning.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system" "system/priv-app/ManagedProvisioning/ManagedProvisioning.apk" \
    "$MODPATH/hdm/ManagedProvisioning.apk/0001-Nuke-Knox-HDM.patch"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$MODPATH/hdm/SecSettings.apk/0001-Nuke-Knox-HDM.patch"
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "$MODPATH/hdm/SecSettingsIntelligence.apk/0001-Nuke-Knox-HDM.patch"
SMALI_PATCH "system_ext" "priv-app/StorageManager/StorageManager.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_VERSION" \
    "HDM_VERSION" \
    > /dev/null
SMALI_PATCH "system_ext" "priv-app/StorageManager/StorageManager.apk" \
    "smali/com/samsung/android/knox/hdm/HdmManager.smali" "replaceall" \
    "$HDM_POLICY_TYPE" \
    "HDM_POLICY_TYPE" \
    > /dev/null
APPLY_PATCH "system_ext" "priv-app/StorageManager/StorageManager.apk" \
    "$MODPATH/hdm/StorageManager.apk/0001-Nuke-Knox-HDM.patch"

unset HDM_VERSION HDM_POLICY_TYPE

# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_BLDP
SMALI_PATCH "system" "system/app/Traceur/Traceur.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system" "system/framework/knoxsdk.jar" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/DeviceDiagnostics/DeviceDiagnostics.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/ManagedProvisioning/ManagedProvisioning.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system_ext" "priv-app/StorageManager/StorageManager.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'
SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
    "smali_classes4/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isBldpEventSupported()Z' 'false'

# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_MPOS
# TODO add services.jar patch
SMALI_PATCH "system" "system/app/Traceur/Traceur.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system" "system/framework/knoxsdk.jar" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/DeviceDiagnostics/DeviceDiagnostics.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/ManagedProvisioning/ManagedProvisioning.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system_ext" "priv-app/StorageManager/StorageManager.apk" \
    "smali/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'
SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
    "smali_classes4/com/samsung/android/knox/integrity/EnhancedAttestationPolicy.smali" "return" \
    'isMposSupported()Z' 'false'

# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_KNOXGUARD
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/knoxguard/services.jar/0001-Disable-KnoxGuard.patch"

# SEC_PRODUCT_FEATURE_SECURITY_SUPPORT_KNOX_MATRIX_AI_PRIVACY
APPLY_PATCH "system" "system/framework/framework.jar" \
    "$MODPATH/kmxai/framework.jar/0001-Nuke-Knox-Matrix-AI-Privacy.patch"

# SEC_PRODUCT_FEATURE_FRAMEWORK_SUPPORT_BLOCKCHAIN_SERVICE
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_BLOCKCHAIN_SERVICE" --delete
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/ProductPackagesRune.smali" "replaceall" \
    "SERVICE_SAMSUNG_BLOCKCHAIN:Z = true" \
    "SERVICE_SAMSUNG_BLOCKCHAIN:Z = false"
if [[ "$TARGET_SECURITY_CONFIG_ESE_CHIP_VENDOR" == "none" ]] && [[ "$TARGET_SECURITY_CONFIG_ESE_COS_NAME" == "none" ]]; then
    APPLY_PATCH "system" "system/framework/services.jar" \
        "$MODPATH/ese+blockchain/services.jar/0001-Nuke-BlockchainTZService.patch"
else
    APPLY_PATCH "system" "system/framework/services.jar" \
        "$MODPATH/blockchain/services.jar/0001-Nuke-BlockchainTZService.patch"
fi

# TODO get rid of the following features
# SEC_PRODUCT_FEATURE_KNOX_SUPPORT_UCS
# SEC_PRODUCT_FEATURE_FRAMEWORK_SUPPORT_MOBILE_PAYMENT

LOG "- Restoring original SourceFile attribute in /system/system/framework/services.jar"
find "$APKTOOL_DIR/system/framework/services.jar" -type f -name "*.smali" -print0 \
    | xargs -0 -I "{}" -P "$(nproc)" sed -i "s/^\.source.*/$SOURCE_FILE_ATTR/g" "{}"

unset SOURCE_FILE_ATTR
