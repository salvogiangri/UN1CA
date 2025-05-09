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

set -e

#[
source "$SRC_DIR/scripts/utils/module_utils.sh" || exit 1

APPLY_MODULE()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH

    if [ ! -d "$MODPATH" ]; then
        LOGE "Folder not found: ${MODPATH//$SRC_DIR\//}"
        return 1
    fi

    if [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ]; then
        MODPATH="$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        LOGE "File not found: ${MODPATH//$SRC_DIR\//}/module.prop"
        return 1
    elif [ -f "$MODPATH/disable" ]; then
        return 0
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//" | sed "s/, /, @/")"
    fi

    LOG_STEP_IN "- Processing \"$MODNAME\" by @$MODAUTH"

    if ! grep -q "^SKIPUNZIP=1$" "$MODPATH/customize.sh" 2> /dev/null; then
        [ -d "$MODPATH/odm" ] && ADD_TO_WORK_DIR "$MODPATH" "odm" "." 0 0 755 "u:object_r:vendor_file:s0"
        [ -d "$MODPATH/product" ] && ADD_TO_WORK_DIR "$MODPATH" "product" "." 0 0 755 "u:object_r:system_file:s0"
        [ -d "$MODPATH/system" ] && ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0"
        [ -d "$MODPATH/system_ext" ] && ADD_TO_WORK_DIR "$MODPATH" "system_ext" "." 0 0 755 "u:object_r:system_file:s0"
        [ -d "$MODPATH/vendor" ] && ADD_TO_WORK_DIR "$MODPATH" "vendor" "." 0 2000 755 "u:object_r:vendor_file:s0"
    fi

    READ_AND_APPLY_PROPS "$MODPATH"

    [ -f "$MODPATH/customize.sh" ] && . "$MODPATH/customize.sh"

    if [ -d "$MODPATH/smali" ]; then
        while IFS= read -r f; do
            APPLY_SMALI_PATCHES "$MODPATH/smali" "$f"
        done < <(find "$MODPATH/smali" -type d \( -name "*.apk" -o -name "*.jar" \) | sed "s|$MODPATH/smali/||")
    fi

    LOG_STEP_OUT

    return 0
}

APPLY_SMALI_PATCHES()
{
    local PATCHES_PATH="$1"
    local TARGET="$2"

    local PARTITION
    PARTITION="$(cut -d "/" -f 1 -s <<< "$TARGET")"

    if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
        LOGE "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    while IFS= read -r p; do
        local FILE="$TARGET"
        [[ "$PARTITION" != "system" ]] && FILE="$(cut -d "/" -f 2- -s <<< "$FILE")"

        # TODO remove
        if [[ "$p" == *"0000-"* ]]; then
            if $ROM_IS_OFFICIAL; then
                [[ "$p" == *"AOSP"* ]] && continue
            else
                [[ "$p" == *"UNICA"* ]] && continue
            fi
        fi

        APPLY_PATCH "$PARTITION" "$FILE" "$p"
    done < <(find "$PATCHES_PATH/$TARGET" -type f -name "*.patch" | sort -n)

    return 0
}

READ_AND_APPLY_PROPS()
{
    local MODPATH="$1"
    local PARTITION

    while IFS= read -r f; do
        PARTITION=$(basename "$f" | sed "s/.prop//")
        IS_VALID_PARTITION_NAME "$PARTITION" || continue

        while read -r l; do
            [[ "$l" == "#"* ]] && continue
            [ ! "$l" ] && continue

            if grep -q -F "=" <<< "$l"; then
                if [ ! "$(cut -d "=" -f 2- -s <<< "$l")" ]; then
                    SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" --delete
                else
                    SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" "$(cut -d "=" -f 2- -s <<< "$l")"
                fi
            else
                LOGE "Malformed string in $f: \"$l\""
                return 1
            fi
        done < "$f"
    done < <(find "$MODPATH" -maxdepth 1 -type f -name "*.prop")

    return 0
}
#]

if [ "$#" != "1" ]; then
    echo "Usage: apply_modules <folder>" >&2
    exit 1
elif [ ! -d "$1" ]; then
    LOGE "Folder not found: ${1//$SRC_DIR\//}"
    exit 1
fi

while IFS= read -r f; do
    APPLY_MODULE "$f"
done < <(find "$1" -mindepth 1 -maxdepth 1 -type d | sort)

exit 0
