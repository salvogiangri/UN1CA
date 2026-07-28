REPOSITORY="https://github.com/UN1CA/proprietary_vendor_samsung_a53x/releases/download"
TARS=(
    # a53xzc (chn_open)
    "A5360ZCSHFYH1_CHC_CHC/BL_A5360ZCSHFYH1_A5360ZCSHFYH1_MQB99877512_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A5360ZCSHFYH1_CHC_CHC/CP_A5360ZCSHFYH1_CP31300261_MQB99843357_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xzh (chn_hk)
    "A5360ZHSHFYI1_TGY_OZS/BL_A5360ZHSHFYI1_A5360ZHSHFYI1_MQB101082970_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A5360ZHSHFYI1_TGY_OZS/CP_A5360ZCSHFYI1_CP31557314_MQB101082970_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xnaxx (eur_open)
    "A536BXXSHFYI1_EUX_OXM/BL_A536BXXSHFYI1_A536BXXSHFYI1_MQB100762209_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536BXXSHFYI1_EUX_OXM/CP_A536BXXSHFYI1_CP31487665_MQB100762209_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xnsxx (cis_open)
    "A536EXXSHFYI4_INS_ODM/BL_A536EXXSHFYI4_A536EXXSHFYI4_MQB100852260_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536EXXSHFYI4_INS_ODM/CP_A536EXXSHFYI4_CP31509747_MQB100852260_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xksx (kor_singlex)
    "A536NKSSCFYH1_KOO_OKR/BL_A536NKSSCFYH1_A536NKSSCFYH1_MQB99401410_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xksx (kor_single)
    "A536NKSSCFYH1_KOO_OKR/CP_A536NKOSCFYH1_CP31202903_MQB99401410_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xdcm (jpn_dcm)
    "SC53COMU1DYF2_DCM_DCM/BL_SC53COMU1DYF2_SC53COMU1DYF2_MQB97872529_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "SC53COMU1DYF2_DCM_DCM/CP_SC53COMU1DYF2_CP30688246_MQB97872529_REV00_user_low_ship_MULTI_CERT.tar.md5"
    # a53xkdi (jpn_kdi)
    "SCG15KDU1DYF1_KDI_QDI/BL_SCG15KDU1DYF1_SCG15KDU1DYF1_MQB96854535_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "SCG15KDU1DYF1_KDI_QDI/CP_SCG15KDU1DYF1_CP30496162_MQB96854535_REV00_user_low_ship_MULTI_CERT.tar.md5"
)

for i in "${TARS[@]}"; do
    LOG "- Downloading $(basename "$i")"
    DOWNLOAD_FILE "$REPOSITORY/$i" "$TMP_DIR/$(basename "$i")" || return 1
done

while IFS= read -r f; do
    FILE_NAME="$(basename "$f")"
    LOG "- Verifying $FILE_NAME"

    FILE_NAME="${FILE_NAME%.md5}"

    # Samsung stores the output of `md5sum` at the very end of the file
    LENGTH="32" # Length of MD5 hash
    LENGTH="$((LENGTH + 2))" # 2 whitespace chars
    LENGTH="$((LENGTH + ${#FILE_NAME}))" # File name without .md5 extension
    LENGTH="$((LENGTH + 1))" # 1 newline char

    STORED_HASH="$(tail -c "$LENGTH" "$f" | cut -d " " -f 1 -s)"
    if [ ! "$STORED_HASH" ] || [[ "${#STORED_HASH}" != "32" ]]; then
        LOG "\033[0;31m! Expected hash could not be parsed\033[0m"
        return 1
    fi

    CALCULATED_HASH="$(head -c-$LENGTH "$f" | md5sum | cut -d " " -f 1 -s)"

    if [[ "$STORED_HASH" != "$CALCULATED_HASH" ]]; then
        LOG "\033[0;31m! File is damaged\033[0m"
        return 1
    fi

    FILE_NAME="$(basename "$f")"
    LOG "- Extracting $FILE_NAME"

    if [[ "$FILE_NAME" == "BL"* ]]; then
        BL_FIRMWARE_VER="$(cut -d "_" -f 2 <<< "$FILE_NAME")"
    elif [[ "$FILE_NAME" != "BL"* ]] && [ ! "$BL_FIRMWARE_VER" ]; then
        LOGE "BL_FIRMWARE_VER is not set"
        return 1
    fi

    FIRMWARE_DIR="$TMP_DIR/firmware/$BL_FIRMWARE_VER"

    if [ ! -d "$TMP_DIR/firmware/$FIRMWARE_DIR" ]; then
        EVAL "mkdir -p \"$FIRMWARE_DIR\"" || return 1
    fi

    EVAL "cd \"$FIRMWARE_DIR\"; tar -xf \"$f\"" || return 1
    EVAL "rm -f \"$f\"" || return 1

    if [ -f "$FIRMWARE_DIR/modem_debug.bin.lz4" ]; then
        LOG "- Deleting ${FIRMWARE_DIR//$TMP_DIR\//}/modem_debug.bin.lz4"
        EVAL "rm -f \"$FIRMWARE_DIR/modem_debug.bin.lz4\"" || return 1
    fi

    unset FILE_NAME LENGTH STORED_HASH CALCULATED_HASH FIRMWARE_DIR
done < <(find "$TMP_DIR" -type f -name "*.md5")

while IFS= read -r f; do
    LOG "- Decompressing ${f#"$TMP_DIR"/}"
    EVAL "lz4 -d --rm \"$f\" \"${f%.lz4}\"" || return 1
done < <(find "$TMP_DIR" -type f -name "*.lz4")

while IFS= read -r f; do
    LOG "- Patching ${f#"$TMP_DIR"/}"
    # https://android.googlesource.com/platform/system/core/+/refs/tags/android-15.0.0_r1/fastboot/fastboot.cpp#1129
    EVAL "printf \"\x03\" | dd of=\"$f\" bs=1 seek=123 count=1 conv=notrunc" || return 1
done < <(find "$TMP_DIR" -type f -name "vbmeta.img")

DTBO_ARCHIVE_URL="$(curl -s --retry 3 "https://api.github.com/repos/UN1CA/kernel_samsung_s5e8825/releases/latest" | \
    jq -r --arg i "^UN1CA_DTBO-.*-a53x_jpn\.tar$" '.assets[] | select(.name | test($i)) | .browser_download_url' \
    | head -n 1)"
DTBO_ARCHIVE="$(basename "$DTBO_ARCHIVE_URL")"

if [ ! "$DTBO_ARCHIVE_URL" ]; then
    ABORT "Failed to fetch DTBO archive URL"
fi

LOG "- Downloading $DTBO_ARCHIVE"
DOWNLOAD_FILE "$DTBO_ARCHIVE_URL" "$TMP_DIR/$DTBO_ARCHIVE" || return 1
LOG "- Extracting $DTBO_ARCHIVE"
EVAL "cd $TMP_DIR; tar -xf \"$TMP_DIR/$DTBO_ARCHIVE\" --transform=\"s|^dtbo.img.lz4$|dtbo_jpn.img.lz4|\"" || return 1
LOG "- Decompressing dtbo_jpn.img.lz4"
EVAL "lz4 -d --rm \"$TMP_DIR/dtbo_jpn.img.lz4\" \"$TMP_DIR/dtbo_jpn.img\"" || return 1
EVAL "rm -f \"$TMP_DIR/$DTBO_ARCHIVE\"" || return 1

unset REPOSITORY TARS BL_FIRMWARE_VER DTBO_ARCHIVE_URL DTBO_ARCHIVE
