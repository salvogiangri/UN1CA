SKIPUNZIP=1

TARGET_FIRMWARE_PATH="$FW_DIR/$(echo -n "$TARGET_FIRMWARE" | sed 's./._.g' | rev | cut -d "_" -f2- | rev)"

if [ -d "$TARGET_FIRMWARE_PATH/system/system/media/audio/pensounds" ]; then
    ADD_TO_WORK_DIR "$SRC_DIR/unica/patches/ultra" "system" "." 0 0 755 "u:object_r:system_file:s0"
else
    echo "Target device is not an Ultra variant. Ignoring"
fi
