# 1080x2340 devices
TWOTHREE_TARGETS=""
# 1080x2400 devices
TWOFOUR_TARGETS="a52sxq a73xq m52xq"

if grep -q -w "$TARGET_CODENAME" <<< "$TWOTHREE_TARGETS" ; then
    LOG "- Adding 2024 boot animation blobs"
    cp -a "$MODPATH/1080x2340/"* "$WORK_DIR/system/system/media"
elif grep -q -w "$TARGET_CODENAME" <<< "$TWOFOUR_TARGETS"; then
    LOG "- Adding 2024 boot animation blobs"
    cp -a "$MODPATH/1080x2400/"* "$WORK_DIR/system/system/media"
else
    LOGW "Unknown boot animation resolution for \"$TARGET_CODENAME\". Skipping"
fi

unset TWOTHREE_TARGETS TWOFOUR_TARGETS
