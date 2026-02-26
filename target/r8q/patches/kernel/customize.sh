KERNEL_REPO="https://github.com/pascua28/kernel_samsung_r8q/releases/latest/download"

LOG_STEP_IN "- Downloading Paradigm kernel"
if [ -f "$WORK_DIR/kernel/boot.img" ]; then
    rm -f "$WORK_DIR/kernel/boot.img"
fi
if [ -f "$WORK_DIR/kernel/dtbo.img" ]; then
    rm -f "$WORK_DIR/kernel/dtbo.img"
fi

DOWNLOAD_FILE "$KERNEL_REPO/boot.img" "$WORK_DIR/kernel/boot.img"
DOWNLOAD_FILE "$KERNEL_REPO/dtbo.img" "$WORK_DIR/kernel/dtbo.img"
LOG_STEP_OUT

unset KERNEL_REPO
