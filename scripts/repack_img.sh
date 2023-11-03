#!/bin/bash
#
# Copyright (C) 2023 BlackMesa123
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"
# ]

if [ "$#" -lt 4 ]; then
    echo "Usage: repack_img <fs> <dir> <file_context> <fs_config>"
    exit 1
fi

case "$1" in
    *"sparse")
        SPARSE=true
        ;&
    "erofs"*)
        EROFS=true
        ;;
    *)
        echo "\"$1\" is not valid fs."
        echo "Available FS:"
        echo "erofs(+sparse)"
        exit 1
        ;;
esac

if [ ! -d "$2" ]; then
    echo "Folder not found: $2"
    exit 1
fi
if [ ! -f "$3" ]; then
    echo "File not found: $3"
    exit 1
fi
if [ ! -f "$4" ]; then
    echo "File not found: $4"
    exit 1
fi

PARTITION=$(basename "$2")
[[ $PARTITION == "system" ]] && MOUNT_POINT="/" || MOUNT_POINT="/$PARTITION"

if $EROFS; then
    mkfs.erofs -zlz4hc,9 -T1640995200 \
        --mount-point="$MOUNT_POINT" --file-contexts="$3" --fs-config="$4" \
        "$2/../$PARTITION.img.raw" "$2"
    if $SPARSE; then
        img2simg "$2/../$PARTITION.img.raw" "$2/../$PARTITION.img" && rm "$2/../$PARTITION.img.raw"
    else
        mv "$2/../$PARTITION.img.raw" "$2/../$PARTITION.img"
    fi
fi

exit 0
