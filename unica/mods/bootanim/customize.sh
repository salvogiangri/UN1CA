SKIPUNZIP=1

TWOTHREE_TARGETS="dm1q dm2q g0q r0q"
TWOFOUR_TARGETS="a52q a52xq a52sxq a71 a72q a73xq m52xq r8q r9q r9q2"
THREETWO_TARGETS="x1q"

if echo "$TWOTHREE_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/2340x1080/"* "$WORK_DIR/system/system/media"
elif echo "$TWOFOUR_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/2400x1080/"* "$WORK_DIR/system/system/media"
elif echo "$THREETWO_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/3200x1440/"* "$WORK_DIR/system/system/media"
else
    echo "Unknown boot animation resolution for \"$TARGET_CODENAME\""
fi

cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/system/"* "$WORK_DIR/system/system"

if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/media/audio/ui/PowerOn\.ogg u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/media/audio/ui/PowerOn.ogg 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
