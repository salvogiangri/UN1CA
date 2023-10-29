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

[ -f "$OUT_DIR/config.sh" ] || exit 1
source "$OUT_DIR/config.sh"

if [ -z "$1" ]; then
    echo "Usage: unsign_bin <image>"
    exit 1
elif [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 1
else
    if avbtool info_image --image "$1" &>/dev/null; then
        echo "Removing AVB footer"
        avbtool erase_footer --image "$1"
    fi
    if grep -q "SignerVer02" "$1"; then
        echo "Removing Samsung v2 signature"
        truncate -s -512 "$1"
    fi
    if grep -q "SignerVer03" "$1"; then
        echo "Removing Samsung v3 signature"
        truncate -s -784 "$1"
    fi
fi

exit 0
