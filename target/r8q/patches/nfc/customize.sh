SKIPUNZIP=1

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

    rm -f "$WORK_DIR/system/system/etc/libnfc-nci.conf"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci-NXP_SN100U.conf" "$WORK_DIR/system/system/etc/libnfc-nci-NXP_SN100U.conf"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci-SLSI.conf" "$WORK_DIR/system/system/etc/libnfc-nci-SLSI.conf"
    sed -i "s/libnfc-nci/libnfc-nci-NXP_SN100U/g" "$WORK_DIR/configs/file_context-system"
    sed -i "s/libnfc-nci/libnfc-nci-NXP_SN100U/g" "$WORK_DIR/configs/fs_config-system"
    echo "/system/etc/libnfc-nci-SLSI\.conf u:object_r:system_file:s0" >> $WORK_DIR/configs/file_context-system
    echo "system/etc/libnfc-nci-SLSI.conf 0 0 644 capabilities=0x0" >> $WORK_DIR/configs/fs_config-system

    SOURCE_LIB_NAME="$(find "$WORK_DIR/system/system/app/NfcNci/lib/arm64" -mindepth 1 -exec basename {} \; | cut -d "_" -f 2)"

    rm -f "$WORK_DIR/system/system/app/NfcNci/lib/arm64/libnfc"*.so
    rm -f "$WORK_DIR/system/system/lib64/libnfc"*.so

    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libnfc"*.so "$WORK_DIR/system/system/lib64"
    # NXP-NFC
    ln -sf "/system/lib64/libnfc_nxpsn_jni.so" "$WORK_DIR/system/system/app/NfcNci/lib/arm64/libnfc_nxpsn_jni.so"
    sed -i "s/libnfc_${SOURCE_LIB_NAME}_jni/libnfc_nxpsn_jni/g" "$WORK_DIR/configs/file_context-system"
    sed -i "s/libnfc-${SOURCE_LIB_NAME}/libnfc-nxpsn/g" "$WORK_DIR/configs/file_context-system"
    sed -i "s/libnfc_${SOURCE_LIB_NAME}_jni/libnfc_nxpsn_jni/g" "$WORK_DIR/configs/fs_config-system"
    sed -i "s/libnfc-${SOURCE_LIB_NAME}/libnfc-nxpsn/g" "$WORK_DIR/configs/fs_config-system"
    # SEC-NFC
    ln -sf "/system/lib64/libnfc_sec_jni.so" "$WORK_DIR/system/system/app/NfcNci/lib/arm64/libnfc_sec_jni.so"
    echo "/system/app/NfcNci/lib/arm64/libnfc_sec_jni\.so u:object_r:system_file:s0" >> $WORK_DIR/configs/file_context-system
    echo "/system/lib64/libnfc-sec\.so u:object_r:system_lib_file:s0" >> $WORK_DIR/configs/file_context-system
    echo "/system/lib64/libnfc_sec_jni\.so u:object_r:system_lib_file:s0" >> $WORK_DIR/configs/file_context-system
    echo "system/app/NfcNci/lib/arm64/libnfc_sec_jni.so 0 0 644 capabilities=0x0" >> $WORK_DIR/configs/fs_config-system
    echo "system/lib64/libnfc-sec.so 0 0 644 capabilities=0x0" >> $WORK_DIR/configs/fs_config-system
    echo "system/lib64/libnfc_sec_jni.so 0 0 644 capabilities=0x0" >> $WORK_DIR/configs/fs_config-system

    # Workaround for pre-U libs
    sed -i "s/\<CoverAttached\>/coverAttached/g" "$WORK_DIR/system/system/lib64/libnfc_nxpsn_jni.so"
    sed -i "s/\<CoverAttached\>/coverAttached/g" "$WORK_DIR/system/system/lib64/libnfc_sec_jni.so"
    sed -i "s/\<StartLedCover\>/startLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_nxpsn_jni.so"
    sed -i "s/\<StartLedCover\>/startLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_sec_jni.so"
    sed -i "s/\<StopLedCover\>/stopLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_nxpsn_jni.so"
    sed -i "s/\<StopLedCover\>/stopLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_sec_jni.so"
    sed -i "s/\<TransceiveLedCover\>/transceiveLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_nxpsn_jni.so"
    sed -i "s/\<TransceiveLedCover\>/transceiveLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_sec_jni.so"

    if [[ ! -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so" ]]; then
        if [[ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc.so" ]]; then
            rm -f "$WORK_DIR/system/system/lib64/libstatslog_nfc.so"
            sed -i "/libstatslog_nfc/d" "$WORK_DIR/configs/file_context-system"
            sed -i "/libstatslog_nfc/d" "$WORK_DIR/configs/fs_config-system"
        fi
    elif [[ ! -f "$WORK_DIR/system/system/lib64/libstatslog_nfc.so" ]]; then
        if [[ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so" ]]; then
            rm -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so"
            sed -i "/libstatslog_nfc_nxp/d" "$WORK_DIR/configs/file_context-system"
            sed -i "/libstatslog_nfc_nxp/d" "$WORK_DIR/configs/fs_config-system"
        fi
    fi
