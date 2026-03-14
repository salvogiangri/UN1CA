REPOSITORY="https://github.com/UN1CA/proprietary_vendor_samsung_a53x/releases/download"
TARS=(
    "SCG15KDU1DYF1_KDI_QDI/BL_SCG15KDU1DYF1_SCG15KDU1DYF1_MQB96854535_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "SCG15KDU1DYF1_KDI_QDI/CP_SCG15KDU1DYF1_CP30496162_MQB96854535_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "SC53COMU1DYF2_DCM_DCM/BL_SC53COMU1DYF2_SC53COMU1DYF2_MQB97872529_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "SC53COMU1DYF2_DCM_DCM/CP_SC53COMU1DYF2_CP30688246_MQB97872529_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A5360ZHSHFYI1_TGY_OZS/BL_A5360ZHSHFYI1_A5360ZHSHFYI1_MQB101082970_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A5360ZHSHFYI1_TGY_OZS/CP_A5360ZCSHFYI1_CP31557314_MQB101082970_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536BXXSHFYI1_EUX_OXM/BL_A536BXXSHFYI1_A536BXXSHFYI1_MQB100762209_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536BXXSHFYI1_EUX_OXM/CP_A536BXXSHFYI1_CP31487665_MQB100762209_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536EXXSHFYI4_INS_ODM/BL_A536EXXSHFYI4_A536EXXSHFYI4_MQB100852260_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536EXXSHFYI4_INS_ODM/CP_A536EXXSHFYI4_CP31509747_MQB100852260_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536NKSSCFYH1_KOO_OKR/BL_A536NKSSCFYH1_A536NKSSCFYH1_MQB99401410_REV00_user_low_ship_MULTI_CERT.tar.md5"
    "A536NKSSCFYH1_KOO_OKR/CP_A536NKOSCFYH1_CP31202903_MQB99401410_REV00_user_low_ship_MULTI_CERT.tar.md5"
)

LOG "- Downloading Bootloader/Modem Archives"
for i in "${TARS[@]}"; do
    EVAL "DOWNLOAD_FILE \"$REPOSITORY/$i\" \"$TMP_DIR/$(basename "$i")\"" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || return 1

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
    if [[ ! "$STORED_HASH" ]] || [[ "${#STORED_HASH}" != "32" ]]; then
        LOG "\033[0;31m! Expected hash could not be parsed\033[0m"
        return 1
    fi

    CALCULATED_HASH="$(head -c-$LENGTH "$f" | md5sum | cut -d " " -f 1 -s)"

    if [[ "$STORED_HASH" != "$CALCULATED_HASH" ]]; then
        LOG "\033[0;31m! File is damaged\033[0m"
        return 1
    fi

    FILE_NAME="$(basename "$f")"
    MODEL="$(echo "$FILE_NAME" | cut -c4-8)"
    if [[ "$MODEL" != "SCG15" ]]; then
        MODEL="${MODEL//SC/SC-}"
        if [[ "$MODEL" != "SC-53C" ]]; then
            MODEL="SM-$MODEL"    
        fi
    fi
    LOG "- Extracting $FILE_NAME"

    if [ ! -d "$TMP_DIR/firmware/$MODEL" ]; then
        EVAL "mkdir -p \"$TMP_DIR/firmware/$MODEL\""
    fi

    EVAL "cd \"$TMP_DIR/firmware/$MODEL\"; tar -xvf \"$f\""
    EVAL "rm \"$f\"" || return 1

    if [ -f "$TMP_DIR/firmware/$MODEL/modem_debug.bin.lz4" ]; then
        LOG "- Deleting firmware/$MODEL/modem_debug.bin.lz4"
        EVAL "rm -f \"$TMP_DIR/firmware/$MODEL/modem_debug.bin.lz4\"" || return 1
    fi

    unset CALCULATED_HASH FILE_NAME LENGTH STORED_HASH
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

unset REPOSITORY
