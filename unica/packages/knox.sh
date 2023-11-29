#====================================================
# FILE:         knox.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Remove native Knox leftovers
#====================================================

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        rm -rf "$FILE_PATH"

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

echo "Remove native Knox leftovers"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libepm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/lipkeyutils.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libknox_filemanager.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libpersona.so"
cp -a --preserve=all "$SRC_DIR/unica/packages/knox/"* "$WORK_DIR/system/system"

exit 0
