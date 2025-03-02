#!/bin/bash
#
# Copyright (C) 2023 Salvo Giangreco
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

if [ "$#" == 0 ]; then
    echo "Usage: unsign_bin <image> (<image>...)"
    exit 1
fi

while [ "$#" != 0 ]; do
    if [ ! -f "$1" ]; then
        echo "File not found: $1"
        exit 1
    else
        if avbtool info_image --image "$1" &>/dev/null; then
            echo "Removing AVB footer signature"
            avbtool erase_footer --image "$1"
        fi
        if head "$1" | grep -q "SignerVer"; then
            echo "Removing Samsung header signature"
            dd if="/dev/zero" of="$1" bs=1 seek=0 count=256 conv=notrunc &>/dev/null
            dd if="/dev/zero" of="$1" bs=1 seek=768 count=256 conv=notrunc &>/dev/null
        fi
        if tail "$1" | grep -q "SignerVer02"; then
            echo "Removing Samsung footer signature"
            truncate -s -512 "$1"
        fi
        if tail "$1" | grep -q "SignerVer03"; then
            echo "Removing Samsung footer signature"
            truncate -s -784 "$1"
        fi
    fi

    shift
done

exit 0
