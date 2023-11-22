#====================================================
# FILE:         vndk.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Check the source VNDK package and
#               replaces it if it's mismatched from
#               target device
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"

source "$OUT_DIR/config.sh"
# ]

if [[ "$SOURCE_VNDK_VERSION" != "$TARGET_VNDK_VERSION" ]]; then
    if $TARGET_HAS_SYSTEM_EXT; then
        SYS_EXT_DIR="$WORK_DIR/system_ext"
        PARTITION="system_ext"
    else
        SYS_EXT_DIR="$WORK_DIR/system/system/system_ext"
        PARTITION="system"
    fi

    if [ ! -f "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex" ]; then
        echo "Adding VNDK v$TARGET_VNDK_VERSION APEX package"

        rm -f "$SYS_EXT_DIR/apex/com.android.vndk.v$SOURCE_VNDK_VERSION.apex"
        cp --preserve=all \
            "$SRC_DIR/unica/patches/vndk/com.android.vndk.v$TARGET_VNDK_VERSION.apex" "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex"
        sed -i "s/com\\\.android\\\.vndk\\\.v$SOURCE_VNDK_VERSION/com\\\.android\\\.vndk\\\.v$TARGET_VNDK_VERSION/g" \
            "$WORK_DIR/configs/file_context-$PARTITION"
        sed -i "s/com.android.vndk.v$SOURCE_VNDK_VERSION/com.android.vndk.v$TARGET_VNDK_VERSION/g" \
            "$WORK_DIR/configs/fs_config-$PARTITION"
    fi
fi

exit 0
