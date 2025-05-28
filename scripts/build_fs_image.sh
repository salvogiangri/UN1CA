#!/usr/bin/env bash
#
# Copyright (C) 2024 Salvo Giangreco
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

# ---------------------------------------------
# Helper functions
# ---------------------------------------------
ROUND_UP_TO_4K() {
    local ROUNDED
    ROUNDED="$(( ($1 + 4095) / 4096 * 4096 ))"
    echo "$ROUNDED"
}

GET_DISK_USAGE() {
    local SIZE
    SIZE=$(du -b -k -s "$1" | cut -f1)
    echo "$(( SIZE * 1024 ))"
}

GET_INODE_USAGE() {
    local INODES SPARE_INODES
    INODES=$(find "$1" -print | wc -l)
    SPARE_INODES=$(( (INODES * 6) / 100 ))
    (( SPARE_INODES < 12 )) && SPARE_INODES=12
    echo "$(( INODES + SPARE_INODES ))"
}

# ---------------------------------------------
# Main: Force EROFS for any input
# ---------------------------------------------
if [ "$#" -ne 3 ]; then
    echo "Usage: build_erofs_image <dir> <file_context> <fs_config>"
    exit 1
fi

IN_DIR="$1"
FC_FILE="$2"
FS_FILE="$3"
PARTITION=$(basename "$IN_DIR")
MOUNT_POINT="$PARTITION"
[[ "$PARTITION" == "system" ]] && MOUNT_POINT="/"

if [ ! -d "$IN_DIR" ]; then
    echo "Folder not found: $IN_DIR"
    exit 1
fi
if [ ! -f "$FC_FILE" ]; then
    echo "File not found: $FC_FILE"
    exit 1
fi
if [ ! -f "$FS_FILE" ]; then
    echo "File not found: $FS_FILE"
    exit 1
fi

# Build EROFS image
IMG_PATH="$IN_DIR/../$PARTITION.img"

echo "- Building $PARTITION.img as erofs..."
mkfs.erofs \
    -zlz4hc,9 -b 4096 \
    --mount-point="$MOUNT_POINT" \
    --fs-config-file="$FS_FILE" \
    --file-contexts="$FC_FILE" \
    -T 1640995200 \
    "$IMG_PATH" "$IN_DIR"

# Run fsck to extract and validate
fsck.erofs --extract "$IMG_PATH"

echo "Done: $IMG_PATH" 
