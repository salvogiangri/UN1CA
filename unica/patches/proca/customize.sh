if [ ! -f "$WORK_DIR/kernel/boot.img" ]; then
    ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/boot.img"
fi

LOG "- Extracting boot.img"

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""
EVAL "cp -a \"$WORK_DIR/kernel/boot.img\" \"$TMP_DIR/boot.img\""

MKBOOTIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/boot.img" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"

if [ ! -f "$TMP_DIR/out/kernel" ]; then
    ABORT "Failed to extract boot.img\n\n$MKBOOTIMG_ARGS"
fi

GZ_COMPRESSED=false
if [[ "$(READ_BYTES_AT "$TMP_DIR/out/kernel" "0" "2")" == "8b1f" ]]; then
    GZ_COMPRESSED=true
fi
if $GZ_COMPRESSED; then
    LOG "- Decompressing kernel image"
    EVAL "cat \"$TMP_DIR/out/kernel\" | gzip -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$TMP_DIR/out/kernel\""
fi

if [[ "$(LC_ALL=C file -b "$TMP_DIR/out/kernel")" != "Linux kernel ARM64"* ]]; then
    ABORT "Kernel image not valid\n\n$(LC_ALL=C file -b "$TMP_DIR/out/kernel")"
fi

PATCHED=false

PROCA_CONFIG_ADDR="$(READ_BYTES_AT "$TMP_DIR/out/kernel" "40" "4")"
if [[ "$PROCA_CONFIG_ADDR" != "00000000" ]] && [[ "$PROCA_CONFIG_ADDR" != "ecefecef" ]]; then
    LOG "- Patching PROCA offset in kernel image header"
    EVAL "printf \"\\xef\\xec\\xef\\xec\" | dd of=\"$TMP_DIR/out/kernel\" bs=1 seek=40 count=4 conv=notrunc"
    PATCHED=true
fi

if xxd -p -c 0 "$TMP_DIR/out/kernel" | grep -q "70726f63615f636f6e66696700"; then
    LOG "- Patching \"70726f63615f636f6e66696700\" to \"6675636b5f755f73616d6d7900\" in kernel image"
    HEX_PATCH "$TMP_DIR/out/kernel" "70726f63615f636f6e66696700" "6675636b5f755f73616d6d7900" > /dev/null
    PATCHED=true
fi

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    EVAL "rm -rf \"$TMP_DIR\""
    unset MKBOOTIMG_ARGS GZ_COMPRESSED PATCHED PROCA_CONFIG_ADDR
    return 0
fi

if $GZ_COMPRESSED; then
    LOG "- Compressing kernel image"
    EVAL "cat \"$TMP_DIR/out/kernel\" | gzip -n -f -9 > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$TMP_DIR/out/kernel\""
fi

LOG "- Repacking boot.img"

EVAL "mkbootimg $MKBOOTIMG_ARGS -o \"$TMP_DIR/new-boot.img\""
echo -n "SEANDROIDENFORCE" >> "$TMP_DIR/new-boot.img"
EVAL "mv -f \"$TMP_DIR/new-boot.img\" \"$WORK_DIR/kernel/boot.img\""

EVAL "rm -rf \"$TMP_DIR\""

unset MKBOOTIMG_ARGS GZ_COMPRESSED PATCHED PROCA_CONFIG_ADDR
