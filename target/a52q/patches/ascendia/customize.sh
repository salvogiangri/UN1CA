SKIPUNZIP=1

# [
ASCENDIA_ZIP="https://github.com/RisenID/kernel_samsung_ascendia_sm7125/releases/download/v3.3/Ascendia_3.3_Vanilla_a572q.zip"

REPLACE_KERNEL_BINARIES()
{
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    echo "Downloading $(basename "$ASCENDIA_ZIP")"
    curl -L -s -o "$TMP_DIR/ascendia.zip" "$ASCENDIA_ZIP"

    echo "Extracting kernel binaries"
    [ -f "$WORK_DIR/kernel/boot.img" ] && rm -rf "$WORK_DIR/kernel/boot.img"
    unzip -q -j "$TMP_DIR/ascendia.zip" "ascendia/a52/oneui.img" -d "$WORK_DIR/kernel"
    mv "$WORK_DIR/kernel/oneui.img" "$WORK_DIR/kernel/boot.img"

    rm -rf "$TMP_DIR"
}
# ]

REPLACE_KERNEL_BINARIES
