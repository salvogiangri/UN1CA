#!/usr/bin/env bash
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

set -Eeu

#[
APPLY_SMALI_PATCHES()
{
    local PATCHES_PATH="$1"
    local TARGET="$2"

    local PATCHES="$(find "$PATCHES_PATH$TARGET" -type f -name "*.patch" -printf "%p ")"

    [ ! -d "$APKTOOL_DIR$TARGET" ] && bash "$SRC_DIR/scripts/apktool.sh" d "$TARGET"

    cd "$APKTOOL_DIR$TARGET"
    for patch in $PATCHES; do
        local OUT
        local COMMIT_NAME
        COMMIT_NAME="$(grep "^Subject:" "$patch" | sed 's/.*PATCH] //')"

        echo "Applying \"$COMMIT_NAME\" to $TARGET"
        OUT="$(patch -p1 -s -t -N --dry-run < "$patch")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N < "$patch" &> /dev/null || true
    done
    cd - &> /dev/null
}

APPLY_MODULE()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH

    if [ ! -d "$MODPATH" ]; then
        echo "Folder not found: $MODPATH"
        exit 1
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        echo "File not found: $MODPATH/module.prop"
        exit 1
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//")"
    fi

    echo "- Processing \"$MODNAME\" by \"$MODAUTH\""

    if ! grep -q '^SKIPUNZIP=1$' "$MODPATH/customize.sh" 2> /dev/null; then
        [ -d "$MODPATH/odm" ] && cp -a --preserve=all "$MODPATH/odm"* "$WORK_DIR/odm"
        [ -d "$MODPATH/product" ] && cp -a --preserve=all "$MODPATH/product"* "$WORK_DIR/product"
        [ -d "$MODPATH/system" ] && cp -a --preserve=all "$MODPATH/system"* "$WORK_DIR/system"
        if $TARGET_HAS_SYSTEM_EXT; then
            [ -d "$MODPATH/system_ext" ] && cp -a --preserve=all "$MODPATH/system_ext"* "$WORK_DIR/system_ext"
        else
            [ -d "$MODPATH/system_ext" ] && cp -a --preserve=all "$MODPATH/system_ext"* "$WORK_DIR/system/system/system_ext"
        fi
        [ -d "$MODPATH/vendor" ] && cp -a --preserve=all "$MODPATH/vendor"* "$WORK_DIR/vendor"
    fi

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
done <<< "$(find "$1" -mindepth 1 -maxdepth 1 -type d)"

exit 0
