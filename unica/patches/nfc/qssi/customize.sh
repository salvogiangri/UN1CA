SKIPUNZIP=1

# [
DECOMPILE()
{
    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        bash "$SRC_DIR/scripts/apktool.sh" d "$1"
    fi
}

APPLY_PATCH()
{
    local PATCH
    local OUT

    DECOMPILE "$1"

    cd "$APKTOOL_DIR/$1"
    PATCH="$SRC_DIR/unica/patches/nfc/qssi/$2"
    OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
        || echo "$OUT" | grep -q "Skipping patch" || false
    patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
    cd - &> /dev/null
}

ADD_TO_WORK_DIR()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    mkdir -p "$WORK_DIR/$(dirname "$FILE_PATH")"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$FILE_PATH" "$WORK_DIR/$FILE_PATH"

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ] || [ -L "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci.conf" ]; then
    ADD_TO_WORK_DIR "system" "system/etc/libnfc-nci.conf" 0 0 644 "u:object_r:system_file:s0"
else
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/libnfc-nci.conf"
fi
[ -f "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci-NXP_SN100U.conf" ] && \
    ADD_TO_WORK_DIR "system" "system/etc/libnfc-nci-NXP_SN100U.conf" 0 0 644 "u:object_r:system_file:s0"
[ -f "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci-NXP_PN553.conf" ] && \
    ADD_TO_WORK_DIR "system" "system/etc/libnfc-nci-NXP_PN553.conf" 0 0 644 "u:object_r:system_file:s0"
[ -f "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci-SLSI.conf" ] && \
    ADD_TO_WORK_DIR "system" "system/etc/libnfc-nci-SLSI.conf" 0 0 644 "u:object_r:system_file:s0"
[ -f "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci-STM_ST21.conf" ] && \
    ADD_TO_WORK_DIR "system" "system/etc/libnfc-nci-STM_ST21.conf" 0 0 644 "u:object_r:system_file:s0"

TARGET_NFC_CHIPNAMES="nxpsn nxppn sec st"
for i in $TARGET_NFC_CHIPNAMES; do
    if [ -f "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so" ]; then
        if [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libnfc_${i}_jni.so" ]; then
            continue
        else
            REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/app/NfcNci/lib/arm64/libnfc_${i}_jni.so"
            REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libnfc-${i}.so"
            REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libnfc_${i}_jni.so"
        fi
    elif [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libnfc_${i}_jni.so" ]; then
        ADD_TO_WORK_DIR "system" "system/app/NfcNci/lib/arm64/libnfc_${i}_jni.so" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "system" "system/lib64/libnfc-${i}.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "system" "system/lib64/libnfc_${i}_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"

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
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so"
    fi
elif [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libstatslog_nfc_nxp.so" ]; then
    ADD_TO_WORK_DIR "system" "system/lib64/libstatslog_nfc_nxp.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc.so" ]; then
    if grep -q -w "libstatslog_nfc" "$WORK_DIR/system/system/lib64/libnfc"*; then
        true
    else
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstatslog_nfc.so"
    fi
elif [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libstatslog_nfc.so" ]; then
    ADD_TO_WORK_DIR "system" "system/lib64/libstatslog_nfc.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_st.so" ]; then
    if grep -q -w "libstatslog_nfc_st" "$WORK_DIR/system/system/lib64/libnfc"*; then
        true
    else
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libstatslog_nfc_st.so"
    fi
elif [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libstatslog_nfc_st.so" ]; then
    ADD_TO_WORK_DIR "system" "system/lib64/libstatslog_nfc_st.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

if [[ "$SOURCE_ESE_CHIP_VENDOR" != "$TARGET_ESE_CHIP_VENDOR" ]] || \
    [[ "$SOURCE_ESE_COS_NAME" != "$TARGET_ESE_COS_NAME" ]]; then
    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/framework/services.jar"

    if [[ "$TARGET_ESE_CHIP_VENDOR" == "none" ]] && [[ "$TARGET_ESE_COS_NAME" == "none" ]]; then
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/app/ESEServiceAgent"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/bin/sem_daemon"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/init/sem.rc"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/privapp-permissions-com.sem.factoryapp.xml"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libsec_sem.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libsec_semHal.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libsec_semRil.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libsec_semTlc.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libspictrl.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.security.sem@1.0.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libsec_sem.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libsec_semHal.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libsec_semRil.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libsec_semTlc.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libspictrl.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.sem@1.0.so"
        REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/SEMFactoryApp"
        cp -a --preserve=all "$SRC_DIR/unica/patches/nfc/qssi/system/"* "$WORK_DIR/system/system"
        APPLY_PATCH "system/framework/framework.jar" "ese/framework.jar/0001-Disable-SemService.patch"
        APPLY_PATCH "system/framework/services.jar" "ese/services.jar/0001-Disable-SemService.patch"
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
