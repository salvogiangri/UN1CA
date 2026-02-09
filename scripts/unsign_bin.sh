#!/usr/bin/env bash
# Copyright (c) 2023 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1
# ]

if [ "$#" == 0 ]; then
    echo "Usage: unsign_bin <image> (<image>...)" >&2
    exit 1
fi

while [ "$#" != 0 ]; do
    if [ ! -f "$1" ]; then
        LOGE "File not found: $1"
        exit 1
    else
        if avbtool info_image --image "$1" &> /dev/null; then
            LOG "- Removing AVB footer signature from $(basename "$1")"
            avbtool erase_footer --image "$1"
        fi
        if head "$1" | grep -q "SignerVer"; then
            LOG "- Removing Samsung header signature from $(basename "$1")"
            dd if="/dev/zero" of="$1" bs=256 seek=0 count=1 conv=notrunc &> /dev/null
            dd if="/dev/zero" of="$1" bs=256 seek=3 count=1 conv=notrunc &> /dev/null
        fi
        if tail "$1" | grep -q "SignerVer02"; then
            LOG "- Removing Samsung footer signature from $(basename "$1")"
            truncate -s -512 "$1"
        fi
        if tail "$1" | grep -q "SignerVer03"; then
            LOG "- Removing Samsung footer signature from $(basename "$1")"
            truncate -s -784 "$1"
        fi
    fi

    shift
done

exit 0
