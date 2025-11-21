[ ! -f "$WORK_DIR/kernel/boot.img" ] && ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/boot.img"

LOG "- Extracting boot.img"

[ -d "$TMP_DIR" ] && EVAL "rm -rf \"$TMP_DIR\""
EVAL "mkdir -p \"$TMP_DIR\""
EVAL "cp -a \"$WORK_DIR/kernel/boot.img\" \"$TMP_DIR/boot.img\""

MKBOOTIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/boot.img" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"

[ ! -f "$TMP_DIR/out/kernel" ] && ABORT "Failed to extract boot.img\n\n$MKBOOTIMG_ARGS"

PATCHED=false
KERNEL_ZIP="https://github.com/frstprjkt/kernel_build_sm7125/releases/download/un1ca/valeryn_20260129_a52q-un1ca.zip"

if [ -f "$TMP_DIR/out/kernel" ]; then
    LOG "- Replacing kernel with Valeryn kernel"
    curl -L -s -o "$TMP_DIR/kernel.zip" "$KERNEL_ZIP"
    unzip -q -j "$TMP_DIR/kernel.zip" "Image.gz" -d "$TMP_DIR/out" && rm "$TMP_DIR/kernel.zip"
    mv "$TMP_DIR/out/Image.gz" "$TMP_DIR/out/kernel"
    PATCHED=true
fi

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    EVAL "rm -rf \"$TMP_DIR\""
    unset MKBOOTIMG_ARGS PATCHED
    return 0
fi

LOG "- Repacking boot.img"

EVAL "mkbootimg $MKBOOTIMG_ARGS -o \"$TMP_DIR/new-boot.img\""
echo -n "SEANDROIDENFORCE" >> "$TMP_DIR/new-boot.img"
EVAL "mv -f \"$TMP_DIR/new-boot.img\" \"$WORK_DIR/kernel/boot.img\""

EVAL "rm -rf \"$TMP_DIR\""

unset MKBOOTIMG_ARGS PATCHED
