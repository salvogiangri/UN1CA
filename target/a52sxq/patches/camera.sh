#====================================================
# FILE:         camera.sh
# AUTHOR:       BlackMesa123, DavidArsene
# DESCRIPTION:  Various camera-related patches
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"
# ]

# Fix camera lock for devices with a rear SLSI sensor
echo "Patching camera HAL"
HAL_LIBS="
$WORK_DIR/vendor/lib/hw/camera.qcom.so
$WORK_DIR/vendor/lib/hw/com.qti.chi.override.so
$WORK_DIR/vendor/lib64/hw/camera.qcom.so
$WORK_DIR/vendor/lib64/hw/com.qti.chi.override.so
"
for f in $HAL_LIBS; do
    sed -i "s/ro.boot.flash.locked/ro.camera.notify_nfc/g" "$f"
done

# Fix SELinux denials
if ! grep -q "Camera End" "$WORK_DIR/vendor/ueventd.rc"; then
    echo "Fix camera SELinux denials"
    echo "" >> "$WORK_DIR/vendor/ueventd.rc"
    cat "$SRC_DIR/target/a52sxq/patches/camera/ueventd" >> "$WORK_DIR/vendor/ueventd.rc"
fi

exit 0
