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

# shellcheck disable=SC1091,SC2001

set -Ee

#[
source "$SRC_DIR/scripts/utils/module_utils.sh"

READ_AND_APPLY_PROPS()
{
    local PARTITION

    for patch in "$1"/*.prop
    do
        PARTITION=$(basename "$patch" | sed 's/.prop//g')
        _IS_VALID_PARTITION_NAME "$PARTITION" || continue

        while read -r i; do
            [[ "$i" = "#"* ]] && continue
            [[ -z "$i" ]] && continue

            if echo -n "$i" | grep -q "="; then
                if [[ -z "$(echo -n "$i" | cut -d "=" -f 2)" ]]; then
                    SET_PROP "$PARTITION" "$(echo -n "$i" | cut -d "=" -f 1)" --delete
                else
                    SET_PROP "$PARTITION" "$(echo -n "$i" | cut -d "=" -f 1)" "$(echo -n "$i" | cut -d "=" -f 2)"
                fi
            else
                echo "Malformed string in $patch: \"$i\""
                return 1
            fi
        done < "$patch"
    done
}

APPLY_SMALI_PATCHES()
{
    local PATCHES_PATH="$1"
    local TARGET="$2"

    [ ! -d "$APKTOOL_DIR$TARGET" ] && bash "$SRC_DIR/scripts/apktool.sh" d "$TARGET"

    cd "$APKTOOL_DIR$TARGET"
    while read -r patch; do
        local OUT
        local COMMIT_NAME
        COMMIT_NAME="$(grep "^Subject:" "$patch" | sed 's/.*PATCH] //')"

        if [[ "$patch" == *"0000-"* ]]; then
            if $ROM_IS_OFFICIAL; then
                [[ "$patch" == *"AOSP"* ]] && continue
            else
                [[ "$patch" == *"UNICA"* ]] && continue
            fi
        fi

        echo "Applying \"$COMMIT_NAME\" to $TARGET"
        OUT="$(patch -p1 -s -t -N --dry-run < "$patch")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N --no-backup-if-mismatch < "$patch" &> /dev/null || true
    done <<< "$(find "$PATCHES_PATH$TARGET" -type f -name "*.patch" | sort -n)"
    cd - &> /dev/null
}

APPLY_MODULE()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH

    if [ ! -d "$MODPATH" ]; then
        echo "Folder not found: $MODPATH"
        return 1
    fi

    if [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ]; then
        MODPATH="$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        echo "File not found: $MODPATH/module.prop"
        return 1
    elif [ -f "$MODPATH/disable" ]; then
        return 0
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//" | sed "s/, /, @/")"
    fi

    echo "- Processing \"$MODNAME\" by @$MODAUTH"

    if ! grep -q '^SKIPUNZIP=1$' "$MODPATH/customize.sh" 2> /dev/null; then
        [ -d "$MODPATH/odm" ] && ADD_TO_WORK_DIR "$MODPATH" "odm" "." 0 0 755 "u:object_r:vendor_file:s0"
        [ -d "$MODPATH/product" ] && ADD_TO_WORK_DIR "$MODPATH" "product" "." 0 0 755 "u:object_r:system_file:s0"
        [ -d "$MODPATH/system" ] && ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0"
        [ -d "$MODPATH/system_ext" ] && ADD_TO_WORK_DIR "$MODPATH" "system_ext" "." 0 0 755 "u:object_r:system_file:s0"
        [ -d "$MODPATH/vendor" ] && ADD_TO_WORK_DIR "$MODPATH" "vendor" "." 0 2000 755 "u:object_r:vendor_file:s0"
    fi

    READ_AND_APPLY_PROPS "$MODPATH"

    [ -f "$MODPATH/customize.sh" ] && . "$MODPATH/customize.sh"

    if [ -d "$MODPATH/smali" ]; then
        local FILES_TO_PATCH
        FILES_TO_PATCH="$(find "$MODPATH/smali" -type d \( -name "*.apk" -o -name "*.jar" \) -printf "%p\n" | sed 's/.*\/smali//')"

        for i in $FILES_TO_PATCH; do
            APPLY_SMALI_PATCHES "$MODPATH/smali" "$i"
        done
    fi
}
#]

if [ "$#" == 0 ]; then
    echo "Usage: apply_modules <folder>"
    exit 1
elif [ ! -d "$1" ]; then
    echo "Folder not found: $1"
    exit 1
fi

while read -r i; do
    APPLY_MODULE "$i"
done <<< "$(find "$1" -mindepth 1 -maxdepth 1 -type d | sort)"

exit 0
