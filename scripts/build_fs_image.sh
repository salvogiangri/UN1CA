#!/usr/bin/env bash
#
# Copyright (C) 2024 BlackMesa123
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

set -eu

# [
ROUND_UP_TO_4K()
{
    local ROUNDED
    ROUNDED="$(echo "$1 + 4095" | bc -l)"
    ROUNDED="$(echo "scale=0; $ROUNDED - ($ROUNDED % 4096)" | bc -l)"
    echo "$ROUNDED"
}

BUILD_EXT4_IMAGE()
{
    local IMG_SIZE="$1"
    local INODES="$2"
    local SPARSE="$3"

    if ! grep -q "lost\\\+found" "$FC_FILE"; then
        if [[ "$PARTITION" == "system" ]]; then
            echo "/lost\+found u:object_r:rootfs:s0" >> "$FC_FILE"
        else
            echo "/$PARTITION/lost\+found $(head -n 1 "$FC_FILE" | cut -d ' ' -f 2)" >> "$FC_FILE"
        fi
    fi

    if ! grep -q "lost+found" "$FS_FILE"; then
        if [[ "$PARTITION" == "system" ]]; then
            echo "lost+found 0 0 700 capabilities=0x0" >> "$FS_FILE"
        else
            echo "$PARTITION/lost+found 0 0 700 capabilities=0x0" >> "$FS_FILE"
        fi
    fi

    SPARSE_FLAG=""
    $SPARSE && SPARSE_FLAG="-s"
    mkuserimg_mke2fs $SPARSE_FLAG \
        "$IN_DIR" "$IN_DIR/../$PARTITION.img" ext4 "$MOUNT_POINT" "$IMG_SIZE" \
        -j 0 -T 1230735600 -C "$FS_FILE" -L "$MOUNT_POINT" \
        -i "$INODES" -M 0 -I 256 "$FC_FILE"
    if ! $SPARSE; then
        e2fsck -f -n "$IN_DIR/../$PARTITION.img"
    fi
}

GET_DISK_USAGE()
{
    local SIZE
    SIZE=$(du -b -k -s "$1" | cut -f 1)
    echo "$SIZE * 1024" | bc -l
}

GET_INODE_USAGE()
{
    local INODES
    local SPARE_INODES

    INODES=$(find "$1" -print | wc -l)
    SPARE_INODES=$(echo "scale=0; ($INODES * 6) / 100" | bc -l)
    [[ "$SPARE_INODES" -lt 12 ]] && SPARE_INODES=12

    echo "$INODES + $SPARE_INODES" | bc -l
}
# ]

if [ "$#" != 4 ]; then
    echo "Usage: build_fs_image <fs> <dir> <file_context> <fs_config>"
    exit 1
fi
if ! echo "$1" | grep -q -w -e "ext4" -e "f2fs" -e "erofs"; then
    echo "\"$1\" is not valid fs."
    echo "Available FS:"
    echo "ext4(+sparse)"
    echo "f2fs(+sparse)"
    echo "erofs(+sparse)"
    exit 1
fi
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

FS_TYPE="$1"
IN_DIR="$2"
FC_FILE="$3"
FS_FILE="$4"

SPARSE=false
[[ "$1" == *"+sparse" ]] && SPARSE=true

PARTITION=$(basename "$2")
MOUNT_POINT="$PARTITION"
[[ "$PARTITION" == "system" ]] && MOUNT_POINT="/"

echo -e "- Building $PARTITION.img as $FS_TYPE...\n"

case "$FS_TYPE" in
    "ext4"*)
        IMG_SIZE="$(GET_DISK_USAGE "$IN_DIR")"
        IMG_SIZE=$(echo "scale=0; ($IMG_SIZE * 1.1) / 1" | bc -l) # 10% headroom to avoid failures
        IMG_SIZE="$(echo "$IMG_SIZE + 16777216" | bc -l)" # temporarely add 16MB of reserved space
        IMG_SIZE="$(ROUND_UP_TO_4K "$IMG_SIZE")"
        INODES="$(GET_INODE_USAGE "$IN_DIR")"

        BUILD_EXT4_IMAGE "$IMG_SIZE" "$INODES" "false"

        IMG_INFO="$(tune2fs -l "$IN_DIR/../$PARTITION.img")"

        # Reduce img size to minimum (add .3% margin)
        FREE_SIZE="$(echo "$IMG_INFO" | grep "Free blocks" | tr -s ' ' | cut -f 3 -d ' ')"
        FREE_SIZE="$(echo "$FREE_SIZE * 4096" | bc -l)"
        IMG_SIZE="$(echo "$IMG_SIZE - $FREE_SIZE" | bc -l)"
        IMG_SIZE="$(echo "scale=0; ($IMG_SIZE * 1003) / 1000" | bc -l)"
        [[ "$IMG_SIZE" -lt 262144 ]] && IMG_SIZE=262144
        IMG_SIZE="$(ROUND_UP_TO_4K "$IMG_SIZE")"

        # Reduce inodes to minimum (add .2% margin or 1 inode, whichever is greater)
        INODES="$(echo "$IMG_INFO" | grep "Inode count" | tr -s ' ' | cut -f 3 -d ' ')"
        FREE_INODES="$(echo "$IMG_INFO" | grep "Free inodes" | tr -s ' ' | cut -f 3 -d ' ')"
        INODES="$(echo "$INODES - $FREE_INODES" | bc -l)"
        SPARE_INODES=$(echo "scale=0; ($INODES * 2) / 100" | bc -l)
        [[ "$SPARE_INODES" -lt 1 ]] && SPARE_INODES=1
        INODES="$(echo "$INODES + $SPARE_INODES" | bc -l)"

        BUILD_EXT4_IMAGE "$IMG_SIZE" "$INODES" "$SPARSE"
        ;;
    "f2fs"*)
        IMG_SIZE="$(GET_DISK_USAGE "$IN_DIR")"
        IMG_SIZE=$(echo "scale=0; ($IMG_SIZE * 1.1) / 1" | bc -l) # 10% headroom to avoid failures
        IMG_SIZE="$(echo "$IMG_SIZE + 16777216" | bc -l)" # temporarely add 16MB of reserved space
        IMG_SIZE="$(ROUND_UP_TO_4K "$IMG_SIZE")"
        [[ "$IMG_SIZE" -lt 18882560 ]] && IMG_SIZE=18882560

        if [[ "$PARTITION" != "system" ]]; then
            sed -i "s/^\/$PARTITION /\/$PARTITION\/$PARTITION /g" "$FC_FILE"
        fi

        SPARSE_FLAG=""
        $SPARSE && SPARSE_FLAG="-S"
        mkf2fsuserimg "$IN_DIR/../$PARTITION.img" "$IMG_SIZE" \
            $SPARSE_FLAG -C "$FS_FILE" -f "$IN_DIR" \
            -s "$FC_FILE" -t "$MOUNT_POINT" -T 1640995200 \
            -L "$MOUNT_POINT" --prjquota --compression \
            --readonly --sldc 0 -b 4096
        ;;
    "erofs"*)
        mkfs.erofs -zlz4hc,9 -b 4096 --mount-point="$MOUNT_POINT" \
            --fs-config-file="$FS_FILE" --file-contexts="$FC_FILE" -T 1640995200 \
            "$IN_DIR/../$PARTITION.img" "$IN_DIR"
        fsck.erofs --extract "$IN_DIR/../$PARTITION.img"
        if $SPARSE; then
            img2simg "$IN_DIR/../$PARTITION.img" "$IN_DIR/../$PARTITION.img.sparse"
            mv "$IN_DIR/../$PARTITION.img.sparse" "$IN_DIR/../$PARTITION.img"
        fi
        ;;
esac

echo ""
exit 0
