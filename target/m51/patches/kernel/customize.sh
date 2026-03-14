LOG_STEP_IN "- Replacing the default kernel with Prime Kernel"
EVAL "rm -rf \"$WORK_DIR/kernel/\"*"
KERNEL_REPO="https://github.com/mehedihjoy0/android_kernel_samsung_sm7150/releases/latest/download"
DOWNLOAD_FILE "$KERNEL_REPO/boot.img" "$WORK_DIR/kernel/boot.img"
DOWNLOAD_FILE "$KERNEL_REPO/dtbo.img" "$WORK_DIR/kernel/dtbo.img"
LOG_STEP_OUT
