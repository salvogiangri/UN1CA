# [
EXTREMEKRNL_REPO="https://github.com/GoRhanHee/M62-backport/releases"

REPLACE_KERNEL_BINARIES()
{
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    ZIP_LINK="$EXTREMEKRNL_REPO/download/${TARGET_CODENAME}_UNOFFICIAL.zip"

    LOG "Downloading $(basename "$ZIP_LINK")"
    curl -L -s -o "$TMP_DIR/krnl.zip" "$ZIP_LINK"

    LOG "Extracting kernel binaries"
    echo $WORK_DIR
    rm -f "$WORK_DIR/kernel/"*.img
    unzip -q -j "$TMP_DIR/krnl.zip" \
        "files/boot.img" "files/dtbo.img" "files/dtb.img" \
        -d "$WORK_DIR/kernel"

    rm -rf "$TMP_DIR"
}

REPLACE_KERNEL_BINARIES
