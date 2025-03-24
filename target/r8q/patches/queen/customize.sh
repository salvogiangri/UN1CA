# [
QUEEN_REPO="https://github.com/smsn-queen-project/krml_queen_kona/releases/download/queen-r8"

REPLACE_KERNEL_BINARIES()
{
    [ -f "$WORK_DIR/kernel/boot.img" ] && rm -rf "$WORK_DIR/kernel/boot.img"
    [ -f "$WORK_DIR/kernel/dtbo.img" ] && rm -rf "$WORK_DIR/kernel/dtbo.img"
    echo "Downloading boot.img"
    curl -L -s -o "$WORK_DIR/kernel/boot.img" "$QUEEN_REPO/boot.img"
    echo "Downloading dtbo.img"
    curl -L -s -o "$WORK_DIR/kernel/dtbo.img" "$QUEEN_REPO/dtbo.img"
}
# ]

REPLACE_KERNEL_BINARIES
