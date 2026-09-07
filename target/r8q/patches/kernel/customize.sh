KERNEL_REPO="https://github.com/UN1CA/kernel_samsung_sm8250/releases/latest/download"

LOG "- Downloading kernel"
if [ -f "$WORK_DIR/kernel/boot.img" ]; then
    EVAL "rm -f \"$WORK_DIR/kernel/boot.img\""
fi
if [ -f "$WORK_DIR/kernel/dtbo.img" ]; then
    EVAL "rm -f \"$WORK_DIR/kernel/dtbo.img\""
fi

DOWNLOAD_FILE "$KERNEL_REPO/boot.img" "$WORK_DIR/kernel/boot.img"
DOWNLOAD_FILE "$KERNEL_REPO/dtbo.img" "$WORK_DIR/kernel/dtbo.img"

unset KERNEL_REPO
