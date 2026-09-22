# [
EXTRACT_RAMDISK()
{
    LOG "- Extracting ${1//$TMP_DIR\//}"
    EVAL "mkdir -p \"$2\""
    if [[ "$(READ_BYTES_AT "$1" "0" "2")" == "8b1f" ]]; then
        EVAL "cat \"$1\" | gzip -d | cpio --quiet -i -D \"$2\""
    elif [[ "$(READ_BYTES_AT "$1" "0" "4")" == "184c2102" ]]; then
        EVAL "cat \"$1\" | lz4 -d | cpio --quiet -i -D \"$2\""
    else
        ABORT "Ramdisk format not valid\n\n$(LC_ALL=C file -b "$1")"
    fi
}

REPACK_BOOT_IMAGE()
{
    local BOARD

    BOARD="$(sed -n "s/.*--board \([^ ]*\).*/\1/p" <<< "$MKBOOTIMG_ARGS")"
    if [ "$BOARD" ]; then
        MKBOOTIMG_ARGS="${MKBOOTIMG_ARGS/--board $BOARD/--board ${BOARD:0:7}001}"
    fi

    LOG "- Repacking $1"
    if [[ "$1" == "vendor_boot.img" ]]; then
        EVAL "mkbootimg $MKBOOTIMG_ARGS --vendor_boot \"$WORK_DIR/kernel/vendor_boot.img\""
    else
        EVAL "mkbootimg $MKBOOTIMG_ARGS -o \"$TMP_DIR/new-$1\""
        echo -n "SEANDROIDENFORCE" >> "$TMP_DIR/new-$1"
        EVAL "mv -f \"$TMP_DIR/new-$1\" \"$WORK_DIR/kernel/$1\""
    fi
    EVAL "rm -rf \"$TMP_DIR/${1%.img}\""
}

REPACK_RAMDISK()
{
    LOG "- Repacking ${2//$TMP_DIR\//}"
    if [[ "$(READ_BYTES_AT "$2" "0" "2")" == "8b1f" ]]; then
        EVAL "mkbootfs \"$1\" | gzip > \"$2\""
    elif [[ "$(READ_BYTES_AT "$2" "0" "4")" == "184c2102" ]]; then
        EVAL "mkbootfs \"$1\" | lz4 -l -12 --favor-decSpeed > \"$2\""
    fi
    EVAL "rm -rf \"$1\""
}

UNPACK_BOOT_IMAGE()
{
    if [ ! -f "$WORK_DIR/kernel/$1" ]; then
        ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/$1"
    fi

    LOG "- Extracting $1"
    EVAL "cp -a \"$WORK_DIR/kernel/$1\" \"$TMP_DIR/$1\""
    if ! MKBOOTIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/$1" --out "$TMP_DIR/${1%.img}" --format mkbootimg 2>&1)"; then
        ABORT "Failed to extract $1\n\n$MKBOOTIMG_ARGS"
    fi
    EVAL "rm -f \"$TMP_DIR/$1\""
}
# ]

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""

LOG_STEP_IN "- Downloading kernel artifacts"
for f in "Image-$TARGET_CODENAME" "dtb-$TARGET_CODENAME" "dtbo-$TARGET_CODENAME.img" "modules-$TARGET_CODENAME.tar.gz"; do
    LOG "- Downloading $f"
    DOWNLOAD_FILE "https://github.com/UN1CA/kernel_samsung_sm7325/releases/latest/download/$f" "$TMP_DIR/$f"
done
LOG_STEP_OUT

UNPACK_BOOT_IMAGE "boot.img"
LOG "- Replacing kernel image"
EVAL "mv -f \"$TMP_DIR/Image-$TARGET_CODENAME\" \"$TMP_DIR/boot/kernel\""
REPACK_BOOT_IMAGE "boot.img"

EVAL "mv -f \"$TMP_DIR/dtbo-$TARGET_CODENAME.img\" \"$WORK_DIR/kernel/dtbo.img\""

UNPACK_BOOT_IMAGE "vendor_boot.img"
LOG "- Replacing dtb"
EVAL "mv -f \"$TMP_DIR/dtb-$TARGET_CODENAME\" \"$TMP_DIR/vendor_boot/dtb\""
EXTRACT_RAMDISK "$TMP_DIR/vendor_boot/vendor_ramdisk" "$TMP_DIR/vendor_boot/ramdisk_extracted"
LOG "- Replacing kernel modules"
EVAL "rm -rf \"$TMP_DIR/vendor_boot/ramdisk_extracted/lib/modules\""
EVAL "mkdir -p \"$TMP_DIR/vendor_boot/ramdisk_extracted/lib/modules\""
EVAL "tar -xzf \"$TMP_DIR/modules-$TARGET_CODENAME.tar.gz\" -C \"$TMP_DIR/vendor_boot/ramdisk_extracted/lib/modules\""
while IFS= read -r f; do
    LOG "- Adding /vendor/firmware/$(basename "$f") to vendor_ramdisk"
    EVAL "mkdir -p \"$TMP_DIR/vendor_boot/ramdisk_extracted/lib/firmware\""
    EVAL "cp -a \"$f\" \"$TMP_DIR/vendor_boot/ramdisk_extracted/lib/firmware/$(basename "$f")\""
done < <(find "$WORK_DIR/vendor/firmware" -mindepth 1 -maxdepth 1 -type d -name "tsp_*" | LC_ALL=C sort)
REPACK_RAMDISK "$TMP_DIR/vendor_boot/ramdisk_extracted" "$TMP_DIR/vendor_boot/vendor_ramdisk"
REPACK_BOOT_IMAGE "vendor_boot.img"

DELETE_FROM_WORK_DIR "vendor" "bin/vendor_modprobe.sh"
DELETE_FROM_WORK_DIR "vendor" "lib/modules"
LOG "- Patching /vendor/etc/init/hw/init.$TARGET_CODENAME.rc"
EVAL "sed -i '/^on early-init\$/{N;N;/modprobe.*\\n\$/d}' \"$WORK_DIR/vendor/etc/init/hw/init.$TARGET_CODENAME.rc\""
LOG "- Patching /vendor/etc/init/hw/init.target.rc"
EVAL "sed -i -e \"/modprobe/d\" -e \"/Load WLAN driver/d\" \"$WORK_DIR/vendor/etc/init/hw/init.target.rc\""
LOG "- Patching /vendor/etc/init/netmgrd.rc"
EVAL "sed -i -e \"/^on property:persist.vendor.data.*_ko_load=/d\" -e \"/modprobe/d\" -e \"/Load rmnet_core driver/d\" \"$WORK_DIR/vendor/etc/init/netmgrd.rc\""
EVAL "sed -i '/^\$/{\$d;N;/\\n\$/D}' \"$WORK_DIR/vendor/etc/init/netmgrd.rc\""

EVAL "rm -rf \"$TMP_DIR\""

unset MKBOOTIMG_ARGS
unset -f EXTRACT_RAMDISK REPACK_BOOT_IMAGE REPACK_RAMDISK UNPACK_BOOT_IMAGE
