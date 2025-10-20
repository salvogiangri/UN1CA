LOG_STEP_IN "- Processing Custom common kernel by @Edgars-cirulis"

PDR="$(pwd)"
KERNEL_URL="https://github.com/fsrb-android-dev/edgars-sm8550-kernel/releases/latest/download/DMXQ-KERNEL-Vanilla.ZIP"
BOOT_EDITOR_URL="https://github.com/cfig/Android_boot_image_editor/releases/download/v15_r1/boot_editor_v15_r1.zip"

REPLACE_KERNEL_BINARIES()
{
    DOWNLOAD_FILE "$KERNEL_URL" "$WORK_DIR/kernel.zip"
    DOWNLOAD_FILE "$BOOT_EDITOR_URL" "$WORK_DIR/kernel/editor.zip"
    unzip -pq "$WORK_DIR/kernel.zip" Image >"$WORK_DIR/kernel/Image"
    cd $WORK_DIR/kernel/
    unzip -q "$WORK_DIR/kernel/editor.zip" -d "$WORK_DIR/kernel/editor"
    mv "$WORK_DIR/kernel/editor/boot_editor_v15_r1" "$WORK_DIR/kernel/booteditor"
    rm -r "$WORK_DIR/kernel/editor"
    rm "$WORK_DIR/kernel/editor.zip"
    rm "$WORK_DIR/kernel.zip"
    mv "$WORK_DIR/kernel/boot.img" "$WORK_DIR/kernel/booteditor/"
    cd "$WORK_DIR/kernel/booteditor/" 
    ./gradlew unpack
    mv ../Image "build/unzip_boot/kernel"
    ./gradlew pack
    mv boot.img.clear ../boot.img
    cd ..
    rm -r booteditor
    cd "$PDR"
}

REPLACE_KERNEL_BINARIES

unset PDR KERNEL_URL BOOT_EDITOR_URL
