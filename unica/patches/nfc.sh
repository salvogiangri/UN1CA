#====================================================
# FILE:         nfc.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Replace source NFC system blobs with
#               stock ones
#====================================================

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
FW_DIR="$OUT_DIR/fw"
WORK_DIR="$OUT_DIR/work_dir"

source "$OUT_DIR/config.sh"
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Replacing NFC blobs with stock"

cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/libnfc-nci.conf" "$WORK_DIR/system/system/etc/libnfc-nci.conf"

TARGET_CHIPNAME="$(grep "ro.vendor.nfc.feature.chipname" "$FW_DIR/${MODEL}_${REGION}/vendor/build.prop" | cut -d "=" -f 2)"
case "$TARGET_CHIPNAME" in
    "NXP_SN100U")
        TARGET_LIB_NAME="nxpsn"
        ;;
    "NXP_PN553")
        TARGET_LIB_NAME="nxppn"
        ;;
    "SLSI")
        TARGET_LIB_NAME="sec"
        ;;
    "STM_ST21")
        TARGET_LIB_NAME="st"
        ;;
    *)
        echo "Unknown target NFC chipname: $TARGET_CHIPNAME"
        exit 1
        ;;
esac

if [[ ! -f "$WORK_DIR/system/system/lib64/libnfc_${TARGET_LIB_NAME}_jni.so" ]]; then
    SOURCE_LIB_NAME="$(find "$WORK_DIR/system/system/app/NfcNci/lib/arm64" -mindepth 1 -exec basename {} \; | cut -d "_" -f 2)"

    rm -f "$WORK_DIR/system/system/app/NfcNci/lib/arm64/libnfc"*.so
    rm -f "$WORK_DIR/system/system/lib64/libnfc"*.so

    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libnfc"*.so "$WORK_DIR/system/system/lib64"
    ln -sf "/system/lib64/libnfc_${TARGET_LIB_NAME}_jni.so" "$WORK_DIR/system/system/app/NfcNci/lib/arm64/libnfc_${TARGET_LIB_NAME}_jni.so"
    sed -i "s/$SOURCE_LIB_NAME/$TARGET_LIB_NAME/g" "$WORK_DIR/configs/file_context-system"
    sed -i "s/$SOURCE_LIB_NAME/$TARGET_LIB_NAME/g" "$WORK_DIR/configs/fs_config-system"

    # Workaround for pre-U libs
    if [[ "$TARGET_API_LEVEL" -lt 34 ]]; then
        sed -i "s/\<CoverAttached\>/coverAttached/g" "$WORK_DIR/system/system/lib64/libnfc_${TARGET_LIB_NAME}_jni.so"
        sed -i "s/\<StartLedCover\>/startLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_${TARGET_LIB_NAME}_jni.so"
        sed -i "s/\<StopLedCover\>/stopLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_${TARGET_LIB_NAME}_jni.so"
        sed -i "s/\<TransceiveLedCover\>/transceiveLedCover/g" "$WORK_DIR/system/system/lib64/libnfc_${TARGET_LIB_NAME}_jni.so"
    fi

    if [[ "$TARGET_LIB_NAME" == "nxp"* ]] && [[ ! -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so" ]]; then
        cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/libstatslog_nfc_nxp.so" "$WORK_DIR/system/system/lib64"
        echo "/system/lib64/libstatslog_nfc_nxp\.so u:object_r:system_lib_file:s0" >> "$WORK_DIR/configs/file_context-system"
        echo "system/lib64/libstatslog_nfc_nxp.so 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    elif [[ -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so" ]]; then
        rm -f "$WORK_DIR/system/system/lib64/libstatslog_nfc_nxp.so"
        sed -i "/libstatslog_nfc_nxp/d" "$WORK_DIR/configs/file_context-system"
        sed -i "/libstatslog_nfc_nxp/d" "$WORK_DIR/configs/fs_config-system"
    fi
fi

exit 0
