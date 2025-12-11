TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
TARGET_SCREEN_HEIGHT="$(printf "%d" "0x$(READ_BYTES_AT "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/media/bootsamsung.qmg" "8" "2")")"

if [[ "$TARGET_SCREEN_HEIGHT" == "2340" ]]; then
    LOG "- Adding 2024 boot animation blobs (1080x2340)"
    EVAL "cp -a \"$MODPATH/1080x2340/\"* \"$WORK_DIR/system/system/media\""
elif [[ "$TARGET_SCREEN_HEIGHT" == "2400" ]]; then
    LOG "- Adding 2024 boot animation blobs (1080x2400)"
    EVAL "cp -a \"$MODPATH/1080x2400/\"* \"$WORK_DIR/system/system/media\""
else
    LOGW "Unknown boot animation resolution for \"$TARGET_CODENAME\". Skipping"
fi

unset TARGET_FIRMWARE_PATH TARGET_SCREEN_HEIGHT
