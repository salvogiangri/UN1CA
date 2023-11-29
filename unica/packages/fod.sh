#====================================================
# FILE:         fod.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Check for target optical FOD support
#               and replace surfaceflinger blobs
#               accordingly if required.
#====================================================

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"

source "$OUT_DIR/config.sh"
# ]

if ! $SOURCE_HAS_OPTICAL_FP_SENSOR; then
    if $TARGET_HAS_OPTICAL_FP_SENSOR; then
        echo "Adding surfaceflinger with optical FOD support"
        cp -a --preserve=all "$SRC_DIR/unica/packages/fod/"* "$WORK_DIR/system/system"
    fi
fi

exit 0
