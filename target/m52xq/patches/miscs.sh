#====================================================
# FILE:         miscs.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Misc patches
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
FW_DIR="$OUT_DIR/fw"
WORK_DIR="$OUT_DIR/work_dir"

source "$OUT_DIR/config.sh"
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ ! -f "$WORK_DIR/odm/ueventd.rc" ]; then
    echo "Add stock /odm/ueventd.rc"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/odm/ueventd.rc" "$WORK_DIR/odm/ueventd.rc"
    echo "/odm/ueventd\.rc u:object_r:vendor_file:s0" >> "$WORK_DIR/configs/file_context-odm"
    echo "odm/ueventd.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-odm"
fi

if [ ! -d "$WORK_DIR/system/spu" ]; then
    echo "Add /spu in rootfs"
    mkdir -p "$WORK_DIR/system/spu"
    echo "/spu u:object_r:spu_file:s0" >> "$WORK_DIR/configs/file_context-system"
    echo "spu 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
fi

exit 0
