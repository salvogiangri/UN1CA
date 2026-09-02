KERNEL_REPO="https://github.com/UN1CA/kernel_samsung_sm7125/releases/latest/download"

LOG "- Downloading Valeryn kernel"
if [ -f "$WORK_DIR/kernel/boot.img" ]; then
    EVAL "rm -f \"$WORK_DIR/kernel/boot.img\""
fi
if [ -f "$WORK_DIR/kernel/dtbo.img" ]; then
    EVAL "rm -f \"$WORK_DIR/kernel/dtbo.img\""
fi

DOWNLOAD_FILE "$KERNEL_REPO/boot-$TARGET_CODENAME.img" "$WORK_DIR/kernel/boot.img"
DOWNLOAD_FILE "$KERNEL_REPO/dtbo-$TARGET_CODENAME.img" "$WORK_DIR/kernel/dtbo.img"

unset KERNEL_REPO
