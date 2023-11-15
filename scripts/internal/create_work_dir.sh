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

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
FW_DIR="$OUT_DIR/fw"
WORK_DIR="$OUT_DIR/work_dir"

CREATE_WORK_DIR()
{
    mkdir -p "$WORK_DIR/configs"

    local COMMON_FOLDERS="odm product system"
    for folder in $COMMON_FOLDERS
    do
        if [ ! -d "$WORK_DIR/$folder" ]; then
            mkdir -p "$WORK_DIR/$folder"
            cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$folder" "$WORK_DIR"
            cp --preserve=all "$FW_DIR/${MODEL}_${REGION}/file_context-$folder" "$WORK_DIR/configs"
            cp --preserve=all "$FW_DIR/${MODEL}_${REGION}/fs_config-$folder" "$WORK_DIR/configs"
        fi
    done

    if $SOURCE_HAS_SYSTEM_EXT; then
        if ! $TARGET_HAS_SYSTEM_EXT; then
            if [ ! -d "$WORK_DIR/system/system/system_ext" ]; then
                rm -rf "$WORK_DIR/system/system_ext"
                rm -f "$WORK_DIR/system/system/system_ext"
                sed -i "/system_ext/d" "$WORK_DIR/configs/file_context-system" \
                    && sed -i "/system_ext/d" "$WORK_DIR/configs/fs_config-system"
                cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system_ext" "$WORK_DIR/system/system"
                ln -sf "/system/system_ext" "$WORK_DIR/system/system_ext"
                echo "/system_ext u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
                echo "system_ext 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
                {
                    sed "s/\/system_ext/\/system\/system_ext/g" "$FW_DIR/${MODEL}_${REGION}/file_context-system_ext"
                } >> "$WORK_DIR/configs/file_context-system"
                echo "system/system_ext 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
                {
                    sed "1d" "$FW_DIR/${MODEL}_${REGION}/fs_config-system_ext" | sed "s/system_ext/system\/system_ext/g"
                } >> "$WORK_DIR/configs/fs_config-system"
            fi
        elif [ ! -d "$WORK_DIR/system_ext" ]; then
            mkdir -p "$WORK_DIR/system_ext"
            cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system_ext" "$WORK_DIR"
            cp --preserve=all "$FW_DIR/${MODEL}_${REGION}/file_context-system_ext" "$WORK_DIR/configs"
            cp --preserve=all "$FW_DIR/${MODEL}_${REGION}/fs_config-system_ext" "$WORK_DIR/configs"
        fi
    fi
}

source "$OUT_DIR/config.sh"

MODEL=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 2)
# ]

mkdir -p "$WORK_DIR"

CREATE_WORK_DIR

exit 0
