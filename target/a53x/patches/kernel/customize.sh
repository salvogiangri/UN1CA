# [
GET_URL()
{
    _CHECK_NON_EMPTY_PARAM "ASSET" "$1" || return 1

    local KERNEL_URL="https://api.github.com/repos/UN1CA/kernel_samsung_s5e8825/releases/latest"

    curl -s --retry 3 "$KERNEL_URL" | jq -r --arg i "$1" '.assets[] | select(.name | test($i)) | .browser_download_url' | head -n 1
}
# ]

KERNEL_ARCHIVE_URL="$(GET_URL "^UN1CA_Kernel-.*-a53x\.tar$")"
DTBO_ARCHIVE_URL="$(GET_URL "^UN1CA_DTBO-.*-a53x\.tar$")"

if [ ! "$KERNEL_ARCHIVE_URL" ]; then
    ABORT "Failed to fetch kernel archive URL"
fi

if [ ! "$DTBO_ARCHIVE_URL" ]; then
    ABORT "Failed to fetch DTBO archive URL"
fi

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""

DOWNLOAD_FILE "$KERNEL_ARCHIVE_URL" "$TMP_DIR/$(basename "$KERNEL_ARCHIVE_URL")"
DOWNLOAD_FILE "$DTBO_ARCHIVE_URL" "$TMP_DIR/$(basename "$DTBO_ARCHIVE_URL")"

while IFS= read -r f; do
    TAR="$(basename "$f")"

    LOG "- Extracting $TAR"
    EVAL "tar -xvf \"$TMP_DIR/$TAR\" -C \"$TMP_DIR\""
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

unset KERNEL_ARCHIVE_URL DTBO_ARCHIVE_URL
unset -f GET_URL
