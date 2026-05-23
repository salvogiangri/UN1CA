REPOSITORY="https://github.com/UN1CA/proprietary_vendor_samsung_exynos2100/releases/download"
TARS=(
    # o1sxxx (eur_open)
    "G991BXXSJHZC2_XEO_OXM/BL_G991BXXSJHZC2_G991BXXSJHZC2_MQB107294787_REV01_user_low_ship_MULTI_CERT.tar.md5"
    "G991BXXSJHZC2_XEO_OXM/CP_G991BXXSJHZA6_CP32677249_MQB105755308_REV01_user_low_ship_MULTI_CERT.tar.md5"
    # o1sksx (kor_single)
    "G991NKSSCHZA9_KOO_OKR/BL_G991NKSSCHZA9_G991NKSSCHZA9_MQB107174732_REV01_user_low_ship_MULTI_CERT.tar.md5"
    "G991NKSSCHZA9_KOO_OKR/CP_G991NKOSCHZA5_CP32602490_MQB105445708_REV01_user_low_ship_MULTI_CERT.tar.md5"
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

    MODEL="$(cut -c4-8 <<< "$FILE_NAME" | sed "s/^/SM-/")"

    if [ ! -d "$TMP_DIR/firmware/$MODEL" ]; then
        EVAL "mkdir -p \"$TMP_DIR/firmware/$MODEL\"" || return 1
    fi

    EVAL "cd \"$TMP_DIR/firmware/$MODEL\"; tar -xf \"$f\"" || return 1
    EVAL "rm -f \"$f\"" || return 1

    if [ -f "$TMP_DIR/firmware/$MODEL/modem_debug.bin.lz4" ]; then
        LOG "- Deleting firmware/$MODEL/modem_debug.bin.lz4"
        EVAL "rm -f \"$TMP_DIR/firmware/$MODEL/modem_debug.bin.lz4\"" || return 1
    fi

    unset FILE_NAME LENGTH STORED_HASH CALCULATED_HASH MODEL
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

unset REPOSITORY TARS
