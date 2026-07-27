# [
PARTITIONS_LIST="system vendor product system_ext odm vendor_dlkm odm_dlkm system_dlkm"

PATCH_FSTAB()
{
    local f

    while IFS= read -r f; do
        if [[ "$f" == *"emmc" ]] || [[ "$f" == *"ramplus" ]]; then
            continue
        fi
        if sed -E -i \
            -e "/^[^[:space:]]+[[:space:]]+\/(${PARTITIONS_LIST// /|})[[:space:]]+/ s/^([^[:space:]]+[[:space:]]+[^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]+/\1\t$TARGET_OS_FILE_SYSTEM_TYPE\t/" \
            -e "/^[^[:space:]]+[[:space:]]+\/(${PARTITIONS_LIST// /|})[[:space:]]+/ s/^([^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]+/\1\tro\t/" \
            "$f"; then
            LOG "- Patching $(sed -e "s|$WORK_DIR||g" -e "s|$TMP_DIR/out/ramdisk_extracted|$BOOT_FILE|g" <<< "$f")"
        fi
        EVAL "uniq \"$f\" \"$TMP_DIR/tmp\" && mv -f \"$TMP_DIR/tmp\" \"$f\""
    done < <(find "$1" -type f -name "fstab.*")
}
# ]

BOOT_FILE="boot.img"
if [ -f "$WORK_DIR/kernel/vendor_boot.img" ]; then
    BOOT_FILE="vendor_boot.img"
fi
if [ ! -f "$WORK_DIR/kernel/$BOOT_FILE" ]; then
    ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/$BOOT_FILE"
fi

LOG "- Extracting $BOOT_FILE"

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""
EVAL "cp -a \"$WORK_DIR/kernel/$BOOT_FILE\" \"$TMP_DIR/$BOOT_FILE\""

MKBOOTIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/$BOOT_FILE" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"

while IFS= read -r f; do
    LOG "- Extracting $BOOT_FILE/$(basename "$f")"

    RAMDISK_FORMAT=""
    if [[ "$(READ_BYTES_AT "$f" "0" "2")" == "8b1f" ]]; then
        RAMDISK_FORMAT="gz"
    fi
    if [[ "$(READ_BYTES_AT "$f" "0" "4")" == "184c2102" ]]; then
        RAMDISK_FORMAT="lz4"
    fi
    if [ ! "$RAMDISK_FORMAT" ]; then
        ABORT "Ramdisk format not valid\n\n$(LC_ALL=C file -b "$f")"
    fi

    EVAL "mkdir -p \"$TMP_DIR/out/ramdisk_extracted\""
    if [[ "$RAMDISK_FORMAT" == "gz" ]]; then
        EVAL "cat \"$f\" | gzip -d | cpio --quiet -i -D \"$TMP_DIR/out/ramdisk_extracted\""
    elif [[ "$RAMDISK_FORMAT" == "lz4" ]]; then
        EVAL "cat \"$f\" | lz4 -d | cpio --quiet -i -D \"$TMP_DIR/out/ramdisk_extracted\""
    fi

    PATCH_FSTAB "$TMP_DIR/out/ramdisk_extracted"

    LOG "- Repacking $BOOT_FILE/$(basename "$f")"

    if [[ "$RAMDISK_FORMAT" == "gz" ]]; then
        EVAL "mkbootfs \"$TMP_DIR/out/ramdisk_extracted\" | gzip > \"$f\""
    elif [[ "$RAMDISK_FORMAT" == "lz4" ]]; then
        EVAL "mkbootfs \"$TMP_DIR/out/ramdisk_extracted\" | lz4 -l -12 --favor-decSpeed > \"$f\""
    fi

    EVAL "rm -rf \"$TMP_DIR/out/ramdisk_extracted\""
done < <(find "$TMP_DIR/out" -type f -name "*ramdisk*" | LC_ALL=C sort)

PATCH_FSTAB "$WORK_DIR/vendor/etc"

LOG "- Repacking $BOOT_FILE"

if [[ "$BOOT_FILE" == "vendor_boot.img" ]]; then
    EVAL "mkbootimg $MKBOOTIMG_ARGS --vendor_boot \"$WORK_DIR/kernel/vendor_boot.img\""
else
    EVAL "mkbootimg $MKBOOTIMG_ARGS -o \"$TMP_DIR/new-boot.img\""
    echo -n "SEANDROIDENFORCE" >> "$TMP_DIR/new-boot.img"
    EVAL "mv -f \"$TMP_DIR/new-boot.img\" \"$WORK_DIR/kernel/boot.img\""
fi

EVAL "rm -rf \"$TMP_DIR\""

unset PARTITIONS_LIST BOOT_FILE MKBOOTIMG_ARGS RAMDISK_FILE RAMDISK_FORMAT
unset -f PATCH_FSTAB
