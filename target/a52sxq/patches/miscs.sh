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

echo "Add stock /odm/ueventd.rc"
if [ ! -f "$WORK_DIR/odm/ueventd.rc" ]; then
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/odm/ueventd.rc" "$WORK_DIR/odm/ueventd.rc"
    echo "/odm/ueventd\.rc u:object_r:vendor_file:s0" >> "$WORK_DIR/configs/file_context-odm"
    echo "odm/ueventd.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-odm"
fi

echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/product/etc/build.prop"

exit 0
