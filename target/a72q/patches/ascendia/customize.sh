SKIPUNZIP=1

# [
ASCENDIA_IMG="https://downloads.simon1511.de/s/nN65wd7AdtBg95A/download/Ascendia_1.0_Vanilla_OneUI_a72q_boot.img"

REPLACE_KERNEL_BINARIES()
{
    [ -f "$WORK_DIR/kernel/boot.img" ] && rm -rf "$WORK_DIR/kernel/boot.img"
    echo "Downloading $(basename "$ASCENDIA_IMG")"
    curl -L -s -o "$WORK_DIR/kernel/boot.img" "$ASCENDIA_IMG"
}
# ]

REPLACE_KERNEL_BINARIES
