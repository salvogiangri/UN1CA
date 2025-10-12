KERNEL_URL="https://github.com/UN1CA/kernel_samsung_a34x/releases/latest/download/Image"
KERNEL_SHA256SUM_URL="https://github.com/UN1CA/kernel_samsung_a34x/releases/latest/download/Image.sha256sum"
KERNEL_BUILDINFO_URL="https://github.com/UN1CA/kernel_samsung_a34x/releases/latest/download/build_info.txt"

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

EVAL "rm \"$TMP_DIR/boot.img\""

if [ ! -f "$TMP_DIR/out/kernel" ]; then
    ABORT "Failed to extract boot.img\n\n$MKBOOTIMG_ARGS"
fi
EVAL "rm \"$TMP_DIR/out/kernel\""

LOG "- Downloading new GKI kernel image"
DOWNLOAD_FILE "$KERNEL_URL" "$TMP_DIR/out/kernel"
DOWNLOAD_FILE "$KERNEL_SHA256SUM_URL" "$TMP_DIR/kernel.sha256sum"
DOWNLOAD_FILE "$KERNEL_BUILDINFO_URL" "$TMP_DIR/kernel_info.txt"

KERNEL_SHA256="$(cat $TMP_DIR/kernel.sha256sum | cut -d' ' -f 1)"
EVAL "rm \"$TMP_DIR/kernel.sha256sum\""

CURRENT_KERNEL_SPL="$(echo "$MKBOOTIMG_ARGS" | grep "\-\-os_patch_level [0-9][0-9][0-9][0-9]-[0-9][0-9]" -o | sed 's/^--os_patch_level //')"
KERNEL_SPL="$(cat "$TMP_DIR/kernel_info.txt" | grep 'asb_level' | sed 's/^asb_level=//' | grep -o "[0-9][0-9][0-9][0-9]-[0-9][0-9]")"
EVAL "rm \"$TMP_DIR/kernel_info.txt\""

MKBOOTIMG_ARGS="$(echo "$MKBOOTIMG_ARGS" | sed "s/\-\-os_patch_level $CURRENT_KERNEL_SPL/\-\-os_patch_level $KERNEL_SPL/")"

if [[ "$(LC_ALL=C file -b "$TMP_DIR/out/kernel")" != "Linux kernel ARM64"* ]]; then
    ABORT "Kernel image not valid. Aborting\n\n$(LC_ALL=C file -b "$TMP_DIR/out/kernel")"
fi

if [[ "$KERNEL_SHA256" != "$(sha256sum "$TMP_DIR/out/kernel" | cut -d' ' -f 1)" ]]; then
    ABORT "Kernel image is corrupted. Aborting"
fi

LOG "- Compressing kernel image"
EVAL "cat \"$TMP_DIR/out/kernel\" | gzip -n -f -9 > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$TMP_DIR/out/kernel\""

LOG "- Repacking boot.img"

EVAL "mkbootimg $MKBOOTIMG_ARGS -o \"$TMP_DIR/new-boot.img\""
echo -n "SEANDROIDENFORCE" >> "$TMP_DIR/new-boot.img"
EVAL "mv -f \"$TMP_DIR/new-boot.img\" \"$WORK_DIR/kernel/boot.img\""

EVAL "rm -rf \"$TMP_DIR\""

unset MKBOOTIMG_ARGS KERNEL_SHA256 CURRENT_KERNEL_SPL KERNEL_SPL
