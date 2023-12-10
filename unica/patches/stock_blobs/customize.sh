SKIPUNZIP=1

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        rm -rf "$FILE_PATH"

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Replacing boot animation blobs with stock"
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

if [ -e $FW_DIR/${MODEL}_${REGION}/system/system/etc/saiv/image_understanding/db/aic_classifier/aic_classifier_cnn.info ]
then
    SAIV_PATH=system/system
    echo $SAIV_PATH
elif [ -e $FW_DIR/${MODEL}_${REGION}/vendor/etc/saiv/image_understanding/db/aic_classifier/aic_classifier_cnn.info ]
then
    SAIV_PATH=vendor
    echo $SAIV_PATH
fi

echo "Replacing saiv blobs with stock"
BLOBS_LIST="
/$SAIV_PATH/etc/saiv/image_understanding/db/aic_classifier/aic_classifier_cnn.info
/$SAIV_PATH/etc/saiv/image_understanding/db/aic_detector/aic_detector_cnn.info
"
for blob in $BLOBS_LIST
do
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}$blob" "$WORK_DIR$blob"
done
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/saiv"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$SAIV_PATH/saiv" "$WORK_DIR/system/system/saiv"
while read -r i; do
    FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
    [ -d "$i" ] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    [ -f "$i" ] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
    echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
done <<< "$(find "$WORK_DIR/system/system/saiv")"

echo "Replacing cameradata blobs with stock"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/cameradata"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/cameradata" "$WORK_DIR/system/system/cameradata"
while read -r i; do
    FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
    [ -d "$i" ] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    [ -f "$i" ] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
    echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
done <<< "$(find "$WORK_DIR/system/system/cameradata")"
