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

# shellcheck disable=SC2001

# [
source "$SRC_DIR/scripts/utils/log_utils.sh"

PRINT_MODULE_INFO()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH
    local MODDESC

    if [ ! -d "$MODPATH" ]; then
        LOGE "Folder not found: $MODPATH"
        exit 1
    fi

    if [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ]; then
        MODPATH="$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        LOGE "File not found: $MODPATH/module.prop"
        exit 1
    elif [ -f "$MODPATH/disable" ]; then
        return 0
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//")"
        MODDESC="$(grep "^description" "$MODPATH/module.prop" | sed "s/description=//")"
    fi

    LOG "-- Module $MODULES_COUNT:"
    LOG "Name: $MODNAME"
    LOG "Author(s): $MODAUTH"
    LOG "Description: $MODDESC"
}
#]

if [ "$#" -gt 0 ]; then
    echo "Usage: print_modules_info" >&2
    echo "This script does not accept any arguments." >&2
    exit 1
fi

MODULES_COUNT=0

while read -r i; do
    ((MODULES_COUNT+=1))
    PRINT_MODULE_INFO "$i"
done <<< "$(find "$SRC_DIR/unica/patches" -mindepth 1 -maxdepth 1 -type d)"

while read -r i; do
    ((MODULES_COUNT+=1))
    PRINT_MODULE_INFO "$i"
done <<< "$(find "$SRC_DIR/unica/mods" -mindepth 1 -maxdepth 1 -type d)"

while read -r i; do
    ((MODULES_COUNT+=1))
    PRINT_MODULE_INFO "$i"
done <<< "$(find "$SRC_DIR/target/$TARGET_CODENAME/patches" -mindepth 1 -maxdepth 1 -type d)"

exit 0
