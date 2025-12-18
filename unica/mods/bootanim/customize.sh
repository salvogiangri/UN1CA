TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

TARGET_SCREEN_RESOLUTION="$(printf "%d" "0x$(READ_BYTES_AT "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/media/bootsamsung.qmg" "6" "2")")"
TARGET_SCREEN_RESOLUTION+="x"
TARGET_SCREEN_RESOLUTION+="$(printf "%d" "0x$(READ_BYTES_AT "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/media/bootsamsung.qmg" "8" "2")")"

if [ -d "$MODPATH/$TARGET_SCREEN_RESOLUTION" ]; then
    LOG "- Adding 2024 boot animation blobs ($TARGET_SCREEN_RESOLUTION)"
    EVAL "cp -a \"$MODPATH/$TARGET_SCREEN_RESOLUTION/\"* \"$WORK_DIR/system/system/media\""
else
    LOGW "No boot animation blobs available for $TARGET_SCREEN_RESOLUTION resolution. Skipping"
fi

unset TARGET_FIRMWARE_PATH TARGET_SCREEN_RESOLUTION
