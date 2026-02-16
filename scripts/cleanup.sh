#!/usr/bin/env bash
# Copyright (c) 2023 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

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
            rm -rf "$OUT_DIR"
            break
            ;;
        "odin")
            LOG "- Cleaning Odin firmwares dir..."
            rm -rf "$ODIN_DIR"
            ;;
        "fw")
            LOG "- Cleaning extracted firmwares dir..."
            rm -rf "$FW_DIR"
            ;;
        "work_dir")
            LOG "- Cleaning ROM work dir..."
            rm -rf "$(dirname "$WORK_DIR")"
            mkdir -p "$(dirname "$WORK_DIR")"
            ;;
        "logs")
            LOG "- Cleaning log files..."
            find "$OUT_DIR" -type f -name "*.log" -delete
            ;;
        "tools")
            LOG "- Cleaning dependencies dir..."
            rm -rf "$TOOLS_DIR"
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
