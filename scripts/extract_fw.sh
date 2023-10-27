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
ODIN_DIR="$OUT_DIR/odin"
FW_DIR="$OUT_DIR/fw"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"

EXTRACT_KERNEL_BINARIES()
{
    local PDR
    PDR="$(pwd)"

    local FILES="boot.img.lz4 dtbo.img.lz4 init_boot.img.lz4 vendor_boot.img.lz4"

    cd "$FW_DIR/${MODEL}_${REGION}"
    for file in $FILES
    do
        [ -f "${file%.lz4}" ] && continue
        tar tf "$AP_TAR" "$file" &>/dev/null || continue
        tar xf "$AP_TAR" "$file" && lz4 -d --rm "$file" "${file%.lz4}"
    done

    echo ""
    cd "$PDR"
}

EXTRACT_OS_BINARIES()
{
    local PDR
    PDR="$(pwd)"

    cd "$FW_DIR/${MODEL}_${REGION}"
    if [ ! -f "super.img" ]; then
        tar xf "$AP_TAR" "super.img.lz4"
        lz4 -d --rm "super.img.lz4" "super.img.sparse"
        simg2img "super.img.sparse" "super.img" && rm "super.img.sparse"
    fi

    echo ""
    cd "$PDR"
}
# ]

source "$SRC_DIR/config.sh"
[ "${#FIRMWARES[@]}" -ge "1" ] || exit 1

mkdir -p "$FW_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)

    if [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
        echo -e "- Extracting $MODEL firmware with $REGION CSC...\n"

        AP_TAR=$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "AP*")

        mkdir -p "$FW_DIR/${MODEL}_${REGION}"
        EXTRACT_KERNEL_BINARIES
        EXTRACT_OS_BINARIES
    else
        echo -e "- $MODEL firmware with $REGION CSC is not downloaded. Skipping...\n"
    fi
done

exit 0
