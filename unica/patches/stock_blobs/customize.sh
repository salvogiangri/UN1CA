SOURCE_FIRMWARE_PATH="$FW_DIR/$(echo -n "$SOURCE_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"
TARGET_FIRMWARE_PATH="$FW_DIR/$(echo -n "$TARGET_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"

echo "Replacing boot animation blobs with stock"
BLOBS_LIST="
system/media/battery_error.spi
system/media/battery_lightning_fast.spi
system/media/battery_lightning.spi
system/media/battery_low.spi
system/media/battery_temperature_error.spi
system/media/battery_temperature_limit.spi
system/media/battery_water_usb.spi
system/media/bootsamsungloop.qmg
system/media/bootsamsung.qmg
system/media/charging_vi_100.spi
system/media/charging_vi_level1.spi
system/media/charging_vi_level2.spi
system/media/charging_vi_level3.spi
system/media/charging_vi_level4.spi
system/media/dock_error_usb.spi
system/media/incomplete_connect.spi
system/media/lcd_density.txt
system/media/percentage.spi
system/media/safety_timer_usb.spi
system/media/shutdown.qmg
system/media/slow_charging_usb.spi
system/media/temperature_limit_usb.spi
system/media/water_protection_usb.spi
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "$blob" 0 0 644 "u:object_r:system_file:s0"
done

echo "Replacing saiv blobs with stock"
if [ -d "$TARGET_FIRMWARE_PATH/system/system/etc/saiv" ]; then
    BLOBS_LIST="
    system/etc/saiv/image_understanding/db/aic_classifier/aic_classifier_cnn.info
    system/etc/saiv/image_understanding/db/aic_detector/aic_detector_cnn.info
    "
    for blob in $BLOBS_LIST
    do
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "$blob" 0 0 644 "u:object_r:system_file:s0"
    done
else
    if [[ -d "$WORK_DIR/system/system/etc/saiv" ]]; then
        DELETE_FROM_WORK_DIR "system" "system/etc/saiv"
    fi
fi
DELETE_FROM_WORK_DIR "system" "system/saiv"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/saiv" 0 0 755 "u:object_r:system_file:s0"
DELETE_FROM_WORK_DIR "system" "system/saiv/textrecognition"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE_PATH" "system" "system/saiv/textrecognition" 0 0 755 "u:object_r:system_file:s0"

echo "Replacing cameradata blobs with stock"
DELETE_FROM_WORK_DIR "system" "system/cameradata"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/cameradata" 0 0 755 "u:object_r:system_file:s0"

if [ -f "$TARGET_FIRMWARE_PATH/system/system/usr/share/alsa/alsa.conf" ]; then
    echo "Add stock alsa.conf"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/usr/share/alsa/alsa.conf" 0 0 644 "u:object_r:system_file:s0"
else
    if [[ -d "$WORK_DIR/system/system/usr/share/alsa" ]]; then
        DELETE_FROM_WORK_DIR "system" "system/usr/share/alsa"
    fi
fi
