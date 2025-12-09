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

# [
source "$SRC_DIR/scripts/utils/log_utils.sh"

PRINT_USAGE()
{
    echo "Usage: cleanup <type> (<type>...)" >&2
    echo " - all ($OUT_DIR)" >&2
    echo " - odin ($ODIN_DIR)" >&2
    echo " - fw ($FW_DIR)" >&2
    echo " - work_dir ($WORK_DIR)" >&2
    echo " - logs ($OUT_DIR/**.log)" >&2
    echo " - tools ($TOOLS_DIR)" >&2
}
# ]

if [ "$#" == 0 ]; then
    PRINT_USAGE
    exit 1
fi

while [ "$#" != 0 ]; do
    case "$1" in
        "all")
            LOG "- Cleaning everything..."
            if [ -d "$OUT_DIR" ]; then
                rm -rf "$OUT_DIR"
            else
                LOGW "Directory not found: $OUT_DIR"
            fi
            break
            ;;
        "odin")
            LOG "- Cleaning Odin firmwares dir..."
            if [ -d "$ODIN_DIR" ]; then
                rm -rf "$ODIN_DIR"
            else
                LOGW "Directory not found: $ODIN_DIR"
            fi
            ;;
        "fw")
            LOG "- Cleaning extracted firmwares dir..."
            if [ -d "$FW_DIR" ]; then
                rm -rf "$FW_DIR"
            else
                LOGW "Directory not found: $FW_DIR"
            fi
            ;;
        "work_dir")
            LOG "- Cleaning ROM work dir..."
            if [ -d "$(dirname "$WORK_DIR")" ]; then
                rm -rf "$(dirname "$WORK_DIR")"
            else
                LOGW "Directory not found: $(dirname "$WORK_DIR")"
            fi
            mkdir -p "$(dirname "$WORK_DIR")"
            ;;
        "logs")
            LOG "- Cleaning log files..."
            if [ -d "$OUT_DIR" ]; then
                find "$OUT_DIR" -type f -name "*.log" -delete
            else
                LOGW "Directory not found: $OUT_DIR"
            fi
            ;;
        "tools")
            LOG "- Cleaning dependencies dir..."
            if [ -d "$TOOLS_DIR" ]; then
                rm -rf "$TOOLS_DIR"
            else
                LOGW "Directory not found: $TOOLS_DIR"
            fi
            git submodule foreach --recursive "git clean -f -d -x" &> /dev/null
            ;;
        *)
            LOGE "\"$1\" is not valid."
            PRINT_USAGE
            exit 1
        ;;
    esac

    shift
done

exit 0
