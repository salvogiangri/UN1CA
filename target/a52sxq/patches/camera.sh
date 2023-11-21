#====================================================
# FILE:         camera.sh
# AUTHOR:       DavidArsene
# DESCRIPTION:  Fix camera lock for devices with a
#               rear SLSI sensor
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"
# ]

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
