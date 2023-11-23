#====================================================
# FILE:         bootanimation.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Replace source boot animation blobs
#               with stock ones
#====================================================

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
FW_DIR="$OUT_DIR/fw"
WORK_DIR="$OUT_DIR/work_dir"

source "$OUT_DIR/config.sh"
# ]

echo "Replacing boot animation blobs with stock"

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

BLOBS_LIST="
/system/system/media/battery_error.spi
/system/system/media/battery_lightning_fast.spi
/system/system/media/battery_lightning.spi
/system/system/media/battery_low.spi
/system/system/media/battery_temperature_error.spi
/system/system/media/battery_temperature_limit.spi
/system/system/media/battery_water_usb.spi
/system/system/media/bootsamsungloop.qmg
/system/system/media/bootsamsung.qmg
/system/system/media/charging_vi_100.spi
/system/system/media/charging_vi_level1.spi
/system/system/media/charging_vi_level2.spi
/system/system/media/charging_vi_level3.spi
/system/system/media/charging_vi_level4.spi
/system/system/media/dock_error_usb.spi
/system/system/media/incomplete_connect.spi
/system/system/media/lcd_density.txt
/system/system/media/percentage.spi
/system/system/media/safety_timer_usb.spi
/system/system/media/shutdown.qmg
/system/system/media/slow_charging_usb.spi
/system/system/media/temperature_limit_usb.spi
/system/system/media/water_protection_usb.spi
"
for blob in $BLOBS_LIST
do
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}$blob" "$WORK_DIR$blob"
done

exit 0
