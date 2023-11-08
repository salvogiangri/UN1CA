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

SPARSE=false
EXT4=false
F2FS=false
EROFS=false
case "$1" in
    *"sparse")
        SPARSE=true
        ;&
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

if $EXT4; then
    [[ $PARTITION == "system" ]] && MOUNT_POINT="/" || MOUNT_POINT="$PARTITION"
    IMG_SIZE=$(du -sb "$2" | cut -f 1)
    IMG_SIZE=$(echo "$IMG_SIZE * 1.05" | bc -l)

    if ! grep -q "lost\+found" "$3"; then
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
    mkuserimg_mke2fs $SPARSE_FLAG -T 1230735600 -C "$4" \
        -L "$MOUNT_POINT" -I 512 "$2" "$2/../$PARTITION.img" \
        ext4 "$MOUNT_POINT" ${IMG_SIZE%.*} "$3"
elif $F2FS; then
    [[ $PARTITION == "system" ]] && MOUNT_POINT="/" || MOUNT_POINT="$PARTITION"
    IMG_SIZE=$(du -sb "$2" | cut -f 1)
    #IMG_SIZE=$(echo "$IMG_SIZE * 1.05" | bc -l)

    $SPARSE && SPARSE_FLAG="-S"
    mkf2fsuserimg "$2/../$PARTITION.img" ${IMG_SIZE%.*} \
        $SPARSE_FLAG -C "$4" -f "$2" \
        -s "$3" -t "$MOUNT_POINT" -T 1640995200 \
        -L "$PARTITION" --prjquota --compression
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

exit 0
