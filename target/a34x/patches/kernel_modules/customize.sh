if [ ! -f "$WORK_DIR/kernel/vendor_boot.img" ]; then
    ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/vendor_boot.img"
fi

LOG "- Extracting vendor_boot.img"

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""
EVAL "cp -a \"$WORK_DIR/kernel/vendor_boot.img\" \"$TMP_DIR/vendor_boot.img\""

MKBOOTIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/vendor_boot.img" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"

EVAL "rm \"$TMP_DIR/vendor_boot.img\""

if [ ! -f "$TMP_DIR/out/vendor_ramdisk00" ]; then
    ABORT "Failed to extract vendor_boot.img\n\n$MKBOOTIMG_ARGS"
fi

LOG "- Extracting vendor_boot ramdisk"

EVAL "mkdir -p \"$TMP_DIR/out/ramdisk_out\""
EVAL "cat \"$TMP_DIR/out/vendor_ramdisk00\" | lz4 -d | cpio --quiet -i -D \"$TMP_DIR/out/ramdisk_out\""
EVAL "rm \"$TMP_DIR/out/vendor_ramdisk00\""

LOG "- Downgrading log_store.ko kernel module"

EVAL "cp \"$MODPATH/log_store.ko\" \"$TMP_DIR/out/ramdisk_out/lib/modules/log_store.ko\""

LOG "- Replacing smcdsd_panel.ko display panel kernel module"

EVAL "cp \"$MODPATH/smcdsd_panel.ko\" \"$TMP_DIR/out/ramdisk_out/lib/modules/smcdsd_panel.ko\""

LOG "- Repacking vendor_boot ramdisk"

EVAL "mkbootfs \"$TMP_DIR/out/ramdisk_out\" | lz4 -l -12 --favor-decSpeed > \"$TMP_DIR/out/vendor_ramdisk00\""
EVAL "rm -rf \"$TMP_DIR/out/ramdisk_out\""

LOG "- Repacking vendor_boot.img"

EVAL "mkbootimg $MKBOOTIMG_ARGS --vendor_boot \"$TMP_DIR/vendor_boot.img\""
EVAL "mv -f \"$TMP_DIR/vendor_boot.img\" \"$WORK_DIR/kernel/vendor_boot.img\""

EVAL "rm -rf \"$TMP_DIR\""

unset MKBOOTIMG_ARGS
