#====================================================
# FILE:         camera.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Various camera-related patches
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"
# ]

# Fix SELinux denials
echo "Fix camera SELinux denials"
if ! grep -q "Camera End" "$WORK_DIR/vendor/ueventd.rc"; then
    echo "" >> "$WORK_DIR/vendor/ueventd.rc"
    cat "$SRC_DIR/target/m52xq/patches/camera/ueventd" >> "$WORK_DIR/vendor/ueventd.rc"
fi

# One UI 6-compatible camera-feature.xml
echo "Replacing camera-feature.xml"
cp -a --preserve=all "$SRC_DIR/target/m52xq/patches/camera/camera-feature.xml" \
    "$WORK_DIR/system/system/cameradata/camera-feature.xml"

exit 0
