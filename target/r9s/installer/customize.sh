LOG "- Downloading BL_G990EXXSIGYI3_G990EXXSIGYI3_MQB100871117_REV01_user_low_ship_MULTI_CERT.tar.md5"
DOWNLOAD_FILE \
    "https://github.com/UN1CA/proprietary_vendor_samsung_exynos2100/releases/download/G990EXXSIGYI3_TPA_OWO/BL_G990EXXSIGYI3_G990EXXSIGYI3_MQB100871117_REV01_user_low_ship_MULTI_CERT.tar.md5" \
    "$TMP_DIR/BL_G990EXXSIGYI3_G990EXXSIGYI3_MQB100871117_REV01_user_low_ship_MULTI_CERT.tar.md5" || return 1
LOG "- Downloading CP_G990EXXSIGYI1_CP31488919_MQB100762461_REV01_user_low_ship_MULTI_CERT.tar.md5"
DOWNLOAD_FILE \
    "https://github.com/UN1CA/proprietary_vendor_samsung_exynos2100/releases/download/G990EXXSIGYI3_TPA_OWO/CP_G990EXXSIGYI1_CP31488919_MQB100762461_REV01_user_low_ship_MULTI_CERT.tar.md5" \
    "$TMP_DIR/CP_G990EXXSIGYI1_CP31488919_MQB100762461_REV01_user_low_ship_MULTI_CERT.tar.md5" || return 1

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

    EVAL "cd \"$TMP_DIR\"; tar -xf \"$f\"" || return 1
    EVAL "rm \"$f\"" || return 1
done < <(find "$TMP_DIR" -type f -name "*.md5")

while IFS= read -r f; do
    LOG "- Decompressing $(basename "$f")"
    EVAL "lz4 -d --rm \"$f\" \"${f%.lz4}\"" || return 1
done < <(find "$TMP_DIR" -type f -name "*.lz4")

LOG "- Deleting modem_debug.bin"
EVAL "rm -f \"$TMP_DIR/modem_debug.bin\"" || return 1

LOG "- Patching vbmeta.img"
# https://android.googlesource.com/platform/system/core/+/refs/tags/android-15.0.0_r1/fastboot/fastboot.cpp#1129
EVAL "printf \"\x03\" | dd of=\"$TMP_DIR/vbmeta.img\" bs=1 seek=123 count=1 conv=notrunc" || return 1

unset FILE_NAME LENGTH STORED_HASH CALCULATED_HASH
