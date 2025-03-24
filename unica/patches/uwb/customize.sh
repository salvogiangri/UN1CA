SKIPUNZIP=1

SOURCE_FIRMWARE_PATH="$FW_DIR/$(echo -n "$SOURCE_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"
TARGET_FIRMWARE_PATH="$FW_DIR/$(echo -n "$TARGET_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"

if [ -f "$TARGET_FIRMWARE_PATH/system/system/etc/libuwb-cal.conf" ]; then
    if ! grep -q "uwbcountrycode" "$WORK_DIR/product/etc/build.prop"; then
        sed -i "/usb.config/a ro.boot.uwbcountrycode=ff" "$WORK_DIR/product/etc/build.prop"
    fi

    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/libuwb-cal.conf" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/etc/pp_model.tflite" 0 0 644 "u:object_r:system_file:s0"

    if [ ! -d "$SOURCE_FIRMWARE_PATH/system/system/app/UwbUci" ]; then
        ADD_TO_WORK_DIR "$SRC_DIR/unica/patches/uwb" "system" "." 0 0 755 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$SRC_DIR/unica/patches/uwb" "system_ext" "." 0 0 755 "u:object_r:system_file:s0"
    fi
fi
