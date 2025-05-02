TARGET_FIRMWARE_PATH="$FW_DIR/$(echo -n "$TARGET_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"

if [ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libnfc-nci.conf" 0 0 644 "u:object_r:system_file:s0"
else
    DELETE_FROM_WORK_DIR "system" "system/etc/libnfc-nci.conf"
fi
[ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-NXP_SN100U.conf" ] && \
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libnfc-nci-NXP_SN100U.conf" 0 0 644 "u:object_r:system_file:s0"
[ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-NXP_PN553.conf" ] && \
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libnfc-nci-NXP_PN553.conf" 0 0 644 "u:object_r:system_file:s0"
[ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-SLSI.conf" ] && \
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libnfc-nci-SLSI.conf" 0 0 644 "u:object_r:system_file:s0"
[ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-STM_ST21.conf" ] && \
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libnfc-nci-STM_ST21.conf" 0 0 644 "u:object_r:system_file:s0"

TARGET_NFC_CHIPNAMES="nxpsn nxppn sec st"
for i in $TARGET_NFC_CHIPNAMES; do
    if [ -f "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so" ]; then
        if [ -f "$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_${i}_jni.so" ]; then
            continue
        else
            DELETE_FROM_WORK_DIR "system" "system/app/NfcNci/lib/arm64/libnfc_${i}_jni.so"
            DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc-${i}.so"
            DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc_${i}_jni.so"
        fi
    elif [ -f "$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_${i}_jni.so" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/app/NfcNci/lib/arm64/libnfc_${i}_jni.so" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/lib64/libnfc-${i}.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/lib64/libnfc_${i}_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"

        # Workaround for pre-U libs
        if [[ "$TARGET_API_LEVEL" -lt 34 ]]; then
            sed -i "s/\<CoverAttached\>/coverAttached/g" "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so"
            sed -i "s/\<StartLedCover\>/startLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so"
            sed -i "s/\<StopLedCover\>/stopLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so"
            sed -i "s/\<TransceiveLedCover\>/transceiveLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so"
        fi
    fi
done

if [ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so" ]; then
    if grep -q -w "libstatslog_nfc_nxp" "$WORK_DIR/system/system/lib64/libnfc"*; then
        true
    else
        DELETE_FROM_WORK_DIR "system" "system/lib64/libstatslog_nfc_nxp.so"
    fi
elif [ -f "$TARGET_FIRMWARE_PATH/system/system/lib64/libstatslog_nfc_nxp.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/lib64/libstatslog_nfc_nxp.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc.so" ]; then
    if grep -q -w "libstatslog_nfc" "$WORK_DIR/system/system/lib64/libnfc"*; then
        true
    else
        DELETE_FROM_WORK_DIR "system" "system/lib64/libstatslog_nfc.so"
    fi
elif [ -f "$TARGET_FIRMWARE_PATH/system/system/lib64/libstatslog_nfc.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/lib64/libstatslog_nfc.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_st.so" ]; then
    if grep -q -w "libstatslog_nfc_st" "$WORK_DIR/system/system/lib64/libnfc"*; then
        true
    else
        DELETE_FROM_WORK_DIR "system" "system/lib64/libstatslog_nfc_st.so"
    fi
elif [ -f "$TARGET_FIRMWARE_PATH/system/system/lib64/libstatslog_nfc_st.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/lib64/libstatslog_nfc_st.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [[ "$SOURCE_ESE_CHIP_VENDOR" != "$TARGET_ESE_CHIP_VENDOR" ]] || \
    [[ "$SOURCE_ESE_COS_NAME" != "$TARGET_ESE_COS_NAME" ]]; then
    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/framework/services.jar"

    if [[ "$TARGET_ESE_CHIP_VENDOR" == "none" ]] && [[ "$TARGET_ESE_COS_NAME" == "none" ]]; then
        DELETE_FROM_WORK_DIR "system" "system/app/ESEServiceAgent"
        DELETE_FROM_WORK_DIR "system" "system/bin/sem_daemon"
        DELETE_FROM_WORK_DIR "system" "system/etc/init/sem.rc"
        DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.sem.factoryapp.xml"
        DELETE_FROM_WORK_DIR "system" "system/lib/libsec_sem.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libsec_semHal.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libsec_semRil.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libsec_semTlc.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libspictrl.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.security.sem@1.0.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libsec_sem.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libsec_semHal.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libsec_semRil.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libsec_semTlc.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libspictrl.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.sem@1.0.so"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/SEMFactoryApp"
        ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib/hidl_tlc_payment_comm_client.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib/libtlc_payment_spay.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/hidl_tlc_payment_comm_client.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libtlc_payment_spay.so" 0 0 644 "u:object_r:system_lib_file:s0"
        APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/nfc/ese/framework.jar/0001-Disable-SemService.patch"
        APPLY_PATCH "system" "system/framework/services.jar" "$SRC_DIR/unica/patches/nfc/ese/services.jar/0001-Disable-SemService.patch"
    else
        FTP="
        system/framework/framework.jar/smali_classes5/com/android/server/SemService.smali
        system/framework/services.jar/smali/com/android/server/SystemConfig.smali
        system/framework/services.jar/smali_classes2/com/samsung/ucm/ucmservice/CredentialManagerService.smali
        "
        for f in $FTP; do
            sed -i "s/\"$SOURCE_ESE_CHIP_VENDOR\"/\"$TARGET_ESE_CHIP_VENDOR\"/g" "$APKTOOL_DIR/$f"
            sed -i "s/\"$SOURCE_ESE_COS_NAME\"/\"$TARGET_ESE_COS_NAME\"/g" "$APKTOOL_DIR/$f"
        done
    fi
fi
