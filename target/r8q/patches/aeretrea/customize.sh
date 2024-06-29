SKIPUNZIP=1

# [
AERETREA_IMG="https://github.com/ata-kaner/r8q_archive/releases/download/Aeretrea-V1/aeretrea.img"

REPLACE_KERNEL_BINARIES()
{
    [ -f "$WORK_DIR/kernel/boot.img" ] && rm -rf "$WORK_DIR/kernel/boot.img"
    echo "Downloading $(basename "$AERETREA_IMG")"
    curl -L -s -o "$WORK_DIR/kernel/boot.img" "$AERETREA_IMG"
}
# ]

REPLACE_KERNEL_BINARIES
