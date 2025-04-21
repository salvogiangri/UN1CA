#!/usr/bin/env bash
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

ALL=false
ODIN=false
FW=false
APKTOOL=false
WORK=false
TOOLS=false

if [ "$#" == 0 ]; then
    echo "Usage: cleanup <type>"
    exit 1
else
    while [ "$#" != 0 ]; do
        case "$1" in
            "all")
                ALL=true
                break
                ;;
            "odin")
                ODIN=true
                ;;
            "fw")
                FW=true
                ;;
            "apktool")
                APKTOOL=true
                ;;
            "work_dir")
                WORK=true
                ;;
            "tools")
                TOOLS=true
                ;;
            *)
                echo "\"$1\" is not valid type."
                echo "Available options (multiple can be accepted):"
                echo "all"
                echo "odin"
                echo "fw"
                echo "apktool"
                echo "work_dir"
                echo "tools"
                exit 1
            ;;
        esac

        shift
    done
fi

if $ALL; then
    echo "- Cleaning everything..."
    rm -rf "$OUT_DIR"
    exit 0
fi

if $ODIN; then
    echo "- Cleaning Odin firmwares dir..."
    rm -rf "$ODIN_DIR"
fi

if $FW; then
    echo "- Cleaning extracted firmwares dir..."
    rm -rf "$FW_DIR"
fi

if $APKTOOL; then
    echo "- Cleaning decompiled apks/jars dir..."
    rm -rf "$APKTOOL_DIR"
fi

if $WORK; then
    echo "- Cleaning ROM work dir (selective rm + multi-folder rsync)..."
    MODEL_T=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
    REGION_T=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)
    MODEL_S=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 1)
    REGION_S=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 2)
    S_FOLDERS="product system"
    T_FOLDERS="vendor odm"

    find "$WORK_DIR" -mindepth 1 -maxdepth 1 \
        -not -name "system" \
        -not -name "vendor" \
        -not -name "product" \
        -not -name "odm" \
        -exec rm -rf {} +


    for folder in $S_FOLDERS; do
        if [[ -d "$FW_DIR/${MODEL_S}_${REGION_S}/$folder" ]]; then
            rsync -a --delete --mkpath \
                "$FW_DIR/${MODEL_S}_${REGION_S}/$folder/" \
                "$WORK_DIR/$folder/"

            mkdir -p "$WORK_DIR/configs"
            rsync -a --mkpath \
                "$FW_DIR/${MODEL_S}_${REGION_S}/file_context-$folder" \
                "$FW_DIR/${MODEL_S}_${REGION_S}/fs_config-$folder" \
                "$WORK_DIR/configs/"
        fi
    done

    for folder in $T_FOLDERS; do
        if [[ -d "$FW_DIR/${MODEL_T}_${REGION_T}/$folder" ]]; then
            rsync -a --delete --mkpath \
                "$FW_DIR/${MODEL_T}_${REGION_T}/$folder/" \
                "$WORK_DIR/$folder/"

            mkdir -p "$WORK_DIR/configs"
            rsync -a \
                "$FW_DIR/${MODEL_T}_${REGION_T}/file_context-$folder" \
                "$FW_DIR/${MODEL_T}_${REGION_T}/fs_config-$folder" \
                "$WORK_DIR/configs/"
        fi
    done
fi

if $TOOLS; then
    echo "- Cleaning dependencies dir..."
    rm -rf "$(dirname "$TOOLS_DIR")"
    git submodule foreach --recursive "git clean -f -d -x" &> /dev/null
fi

exit 0
