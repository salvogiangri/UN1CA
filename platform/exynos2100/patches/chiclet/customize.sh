KERNEL_API_URL="https://api.github.com/repos/UN1CA/kernel_samsung_exynos2100/releases/tags/v5.5"
KERNEL_DL_BASE="https://github.com/UN1CA/kernel_samsung_exynos2100/releases/download/v5.5"

LOG_STEP_IN "- Downloading vanilla kernel variant"
if [[ -d "$TMP_DIR" ]]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
mkdir -p "$TMP_DIR"

KERNEL_ARCHIVE="$(
    curl -s "$KERNEL_API_URL" \
    | grep -oE "ChicletKernel-.*_${TARGET_CODENAME}_VANILLA_OFFICIAL_.*\.zip" \
    | sort -u \
    | tail -n 1
)"

DOWNLOAD_FILE "$KERNEL_DL_BASE/$KERNEL_ARCHIVE" "$TMP_DIR/$KERNEL_ARCHIVE"

for i in "boot" "dtbo" "vendor_boot"; do
    LOG "- Replacing $i.img"

    EVAL "unzip -o \"$TMP_DIR/$KERNEL_ARCHIVE\" \"files/$i.img\" -d \"$TMP_DIR\""

    if [[ -f "$WORK_DIR/kernel/$i.img" ]]; then
        EVAL "rm -f \"$WORK_DIR/kernel/$i.img\""
    fi

    EVAL "mv \"$TMP_DIR/files/$i.img\" \"$WORK_DIR/kernel/$i.img\""
done

EVAL "rm -rf \"$TMP_DIR\""

LOG_STEP_OUT

unset KERNEL_ARCHIVE KERNEL_API_URL KERNEL_DL_BASE
