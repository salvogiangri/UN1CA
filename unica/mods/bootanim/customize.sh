XML_FILE="$WORK_DIR/system/system/cameradata/camera-feature.xml"
if [ ! -f "$XML_FILE" ]; then
    ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/system/system/cameradata/camera-feature.xml"
fi

if grep -q "_CAMCORDER_RESOLUTION_FEATURE_MAP_2336X1080" "$XML_FILE" && \
        ! $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
    LOG "- Adding 2024 boot animation blobs (1080x2340)"
    EVAL "cp -a \"$MODPATH/1080x2340/\"* \"$WORK_DIR/system/system/media\""
elif grep -q "_CAMCORDER_RESOLUTION_FEATURE_MAP_2400X1080" "$XML_FILE" && \
        ! $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
    LOG "- Adding 2024 boot animation blobs (1080x2400)"
    EVAL "cp -a \"$MODPATH/1080x2400/\"* \"$WORK_DIR/system/system/media\""
else
    LOGW "Unknown boot animation resolution for \"$TARGET_CODENAME\". Skipping"
fi

unset XML_FILE
