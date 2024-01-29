SKIPUNZIP=1

# [
ASCENDIA_IMG="https://downloads.simon1511.de/s/SHzASGR4nYTbjQ4/download/Ascendia_1.0_Vanilla_OneUI_a52q_boot.img"

REPLACE_KERNEL_BINARIES()
{
    [ -f "$WORK_DIR/kernel/boot.img" ] && rm -rf "$WORK_DIR/kernel/boot.img"
    echo "Downloading $(basename "$ASCENDIA_IMG")"
    curl -L -s -o "$WORK_DIR/kernel/boot.img" "$ASCENDIA_IMG"
}
# ]

REPLACE_KERNEL_BINARIES
