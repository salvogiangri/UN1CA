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

# shellcheck disable=SC2069

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"
# ]

if [ "$#" -lt 4 ]; then
    echo "Usage: build_fs_image <fs> <dir> <file_context> <fs_config>"
    exit 1
fi

[[ $1 == *"sparse" ]] && SPARSE=true || SPARSE=false
EXT4=false
F2FS=false
EROFS=false
case "$1" in
    "ext4"*)
        EXT4=true
        ;;
    "f2fs"*)
        F2FS=true
        ;;
    "erofs"*)
        EROFS=true
        ;;
    *)
        echo "\"$1\" is not valid fs."
        echo "Available FS:"
        echo "ext4(+sparse)"
        echo "f2fs(+sparse)"
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

echo -e "- Building $PARTITION.img as $1...\n"

if $EXT4; then
    [[ $PARTITION == "system" ]] && MOUNT_POINT="/" || MOUNT_POINT="$PARTITION"

    IMG_SIZE=$(du -sb "$2" | cut -f 1)
    IMG_SIZE=$(echo "$IMG_SIZE * 1.01" | bc -l)
    IMG_SIZE=${IMG_SIZE%.*}
    [[ "$IMG_SIZE" -lt 2097152 ]] && IMG_SIZE=2097152

    INODES=$(find "$2" -print | wc -l)
    SPARE_INODES=$(echo "$INODES * 6 / 100" | bc -l)
    SPARE_INODES=${SPARE_INODES%.*}
    [[ "$SPARE_INODES" -lt 12 ]] && SPARE_INODES=12

    if ! grep -q "lost\\\+found" "$3"; then
        [[ $PARTITION == "system" ]] && echo "/lost\+found u:object_r:rootfs:s0" >> "$3"
        [[ $PARTITION == "odm" ]] && echo "/odm/lost\+found u:object_r:vendor_file:s0" >> "$3"
        [[ $PARTITION == "product" ]] && echo "/product/lost\+found u:object_r:system_file:s0" >> "$3"
        [[ $PARTITION == "vendor" ]] && echo "/vendor/lost\+found u:object_r:vendor_file:s0" >> "$3"
    fi

    if ! grep -q "lost+found" "$4"; then
        [[ $PARTITION == "system" ]] \
            && echo "lost+found 0 0 700 capabilities=0x0" >> "$4" || echo "$PARTITION/lost+found 0 0 700 capabilities=0x0" >> "$4"
    fi

    $SPARSE && SPARSE_FLAG="-s"
    mkuserimg_mke2fs $SPARSE_FLAG -j 0 -T 1230735600 -C "$4" \
        -L "$MOUNT_POINT" -i "$(echo "$INODES + $SPARE_INODES" | bc -l)" -I 256 \
        "$2" "$2/../$PARTITION.img" ext4 "$MOUNT_POINT" "$IMG_SIZE" "$3" 2>&1 > /dev/null
elif $F2FS; then
    [[ $PARTITION == "system" ]] && MOUNT_POINT="/" || MOUNT_POINT="$PARTITION"
    IMG_SIZE=$(du -sb "$2" | cut -f 1)
    IMG_SIZE=$(echo "$IMG_SIZE * 1.05" | bc -l)
    IMG_SIZE=${IMG_SIZE%.*}

    $SPARSE && SPARSE_FLAG="-S"
    mkf2fsuserimg "$2/../$PARTITION.img" "$IMG_SIZE" \
        $SPARSE_FLAG -C "$4" -f "$2" \
        -s "$3" -t "$MOUNT_POINT" -T 1640995200 \
        -L "$MOUNT_POINT" --prjquota --compression
elif $EROFS; then
    [[ $PARTITION == "system" ]] && MOUNT_POINT="/" || MOUNT_POINT="/$PARTITION"

    mkfs.erofs -zlz4hc,9 -b 4096 -T 1640995200 \
        --mount-point="$MOUNT_POINT" --file-contexts="$3" --fs-config="$4" \
        "$2/../$PARTITION.img.raw" "$2"
    if $SPARSE; then
        img2simg "$2/../$PARTITION.img.raw" "$2/../$PARTITION.img" && rm "$2/../$PARTITION.img.raw"
    else
        mv "$2/../$PARTITION.img.raw" "$2/../$PARTITION.img"
    fi
fi

echo ""
exit 0
