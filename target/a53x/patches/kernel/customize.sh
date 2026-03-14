# [
GET_URL()
{
    _CHECK_NON_EMPTY_PARAM "ASSET" "$1" || return 1

    local KERNEL_URL="https://api.github.com/repos/UN1CA/kernel_samsung_s5e8825/releases/latest"

    curl -s "$KERNEL_URL" | jq -r --arg i "$1" '.assets[] | select(.name | test($i)) | .browser_download_url' | head -n 1
}
# ]

KERNEL_ARCHIVE_URL="$(GET_URL "^UN1CA_Kernel-.*-a53x\.tar$")"
DTBO_ARCHIVE_URL="$(GET_URL "^UN1CA_DTBO-.*-a53x\.tar$")"
DTBO_JPN_ARCHIVE_URL="$(GET_URL "^UN1CA_DTBO-.*-a53x_jpn\.tar$")"

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""

DOWNLOAD_FILE "$KERNEL_ARCHIVE_URL" "$TMP_DIR/$(basename "$KERNEL_ARCHIVE_URL")" &
DOWNLOAD_FILE "$DTBO_ARCHIVE_URL" "$TMP_DIR/$(basename "$DTBO_ARCHIVE_URL")" &
DOWNLOAD_FILE "$DTBO_JPN_ARCHIVE_URL" "$TMP_DIR/$(basename "$DTBO_JPN_ARCHIVE_URL")" &

# shellcheck disable=SC2046
wait $(jobs -p) || return 1

while IFS= read -r f; do
    TAR="$(basename "$f")"

    LOG "- Extracting $TAR"
    if [[ "$TAR" == "$(basename "$DTBO_JPN_ARCHIVE_URL")" ]]; then
        EVAL "tar -xvf \"$TMP_DIR/$TAR\" --transform=\"s|^dtbo.img.lz4$|dtbo_jpn.img.lz4|\" -C \"$TMP_DIR\""
    else
        EVAL "tar -xvf \"$TMP_DIR/$TAR\" -C \"$TMP_DIR\""
    fi
    EVAL "rm -f \"$TMP_DIR/$TAR\""

    unset TAR
done < <(find "$TMP_DIR" -maxdepth 1 -type f -name "*.tar")

while IFS= read -r f; do
    IMG="$(basename "${f%.lz4}")"

    LOG "- Extracting $IMG.lz4"
    EVAL "lz4 -df --rm \"$TMP_DIR/$IMG.lz4\" \"$TMP_DIR/$IMG\""

    if [ -f "$WORK_DIR/kernel/$IMG" ]; then
        LOG "- Replacing $IMG"
        EVAL "rm -f \"$WORK_DIR/kernel/$IMG\""
    else
        LOG "- Adding $IMG to ${WORK_DIR//$SRC_DIR\//}/kernel"
    fi
    EVAL "mv \"$TMP_DIR/$IMG\" \"$WORK_DIR/kernel/$IMG\""

    unset IMG
done < <(find "$TMP_DIR" -maxdepth 1 -type f -name "*.img.lz4")

EVAL "rm -rf \"$TMP_DIR\""

unset DTBO_ARCHIVE_URL DTBO_JPN_ARCHIVE_URL KERNEL_ARCHIVE_URL
unset -f GET_URL
