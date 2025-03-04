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
    echo "- Cleaning ROM work dir..."
    rm -rf "$WORK_DIR"
fi

if $TOOLS; then
    echo "- Cleaning dependencies dir..."
    rm -rf "$(dirname "$TOOLS_DIR")"
    git submodule foreach --recursive "git clean -f -d -x" &> /dev/null
fi

exit 0
