SKIPUNZIP=1

if $SOURCE_HAS_OPTICAL_FP_SENSOR; then
    if ! $TARGET_HAS_OPTICAL_FP_SENSOR; then
        cp -a --preserve=all "$SRC_DIR/unica/packages/fod/essi/system/"* "$WORK_DIR/system/system"
    else
        echo "TARGET_HAS_OPTICAL_FP_SENSOR is set. Ignoring"
    fi
else
    echo "SOURCE_HAS_OPTICAL_FP_SENSOR is not set. Ignoring"
fi
