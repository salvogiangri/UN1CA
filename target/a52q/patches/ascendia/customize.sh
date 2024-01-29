SKIPUNZIP=1

# [
ASCENDIA_IMG="https://downloads.simon1511.de/s/SHzASGR4nYTbjQ4/download/Ascendia_1.0_Vanilla_OneUI_a52q_boot.img"

REPLACE_KERNEL_BINARIES()
{
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    echo "Downloading $(basename "$ASCENDIA_IMG")"
    curl -L -s -o "$TMP_DIR/boot.img" "$ASCENDIA_IMG"

    echo "Extracting kernel binaries"
    rm -f "$WORK_DIR/kernel/boot.img"
    cp "$TMP_DIR/boot.img" "$WORK_DIR/kernel/"

    rm -rf "$TMP_DIR"
}
# ]

REPLACE_KERNEL_BINARIES
