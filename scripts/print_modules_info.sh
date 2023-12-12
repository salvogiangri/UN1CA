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

# shellcheck disable=SC2001

set -Eeu

# [
GEN_KNOX_SUBDIR()
{
    local SOURCE_SUBDIR
    local TARGET_SUBDIR

    $SOURCE_HAS_KNOX_DUALDAR && SOURCE_SUBDIR+="ddar_"
    $SOURCE_HAS_KNOX_SDP && SOURCE_SUBDIR+="sdp_"
    SOURCE_SUBDIR="$(echo "$SOURCE_SUBDIR" | sed "s/_$//")"
    [ -z "$SOURCE_SUBDIR" ] && SOURCE_SUBDIR="none"

    $TARGET_HAS_KNOX_DUALDAR && TARGET_SUBDIR+="ddar_"
    $TARGET_HAS_KNOX_SDP && TARGET_SUBDIR+="sdp_"
    TARGET_SUBDIR="$(echo "$TARGET_SUBDIR" | sed "s/_$//")"
    [ -z "$TARGET_SUBDIR" ] && TARGET_SUBDIR="none"

    if [[ "$SOURCE_SUBDIR" != "$TARGET_SUBDIR" ]]; then
        echo "$TARGET_SUBDIR"
    else
        echo ""
    fi
}

PRINT_MODULE_INFO()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH
    local MODDESC

    if [ ! -d "$MODPATH" ]; then
        echo "Folder not found: $MODPATH"
        exit 1
    fi

    if [[ "$MODPATH" == *"unica/packages/knox" ]]; then
        local SUBDIR
        SUBDIR=$(GEN_KNOX_SUBDIR)
        [ -z "$SUBDIR" ] && return 0
        MODPATH="$MODPATH/$SUBDIR"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        echo "File not found: $MODPATH/module.prop"
        exit 1
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//")"
        MODDESC="$(grep "^description" "$MODPATH/module.prop" | sed "s/description=//")"
    fi

    echo "-- Module $MODULES_COUNT:"
    echo "Name: $MODNAME"
    echo "Author(s): $MODAUTH"
    echo "Description: $MODDESC"
}
#]

if [ "$#" -gt 0 ]; then
    echo "Usage: print_modules_info"
    echo "This cmd does not accepts any arguments."
    exit 1
fi

MODULES_COUNT=0

while read -r i; do
    ((MODULES_COUNT+=1))
    PRINT_MODULE_INFO "$i"
done <<< "$(find "$SRC_DIR/unica/packages" -mindepth 1 -maxdepth 1 -type d)"

while read -r i; do
    ((MODULES_COUNT+=1))
    PRINT_MODULE_INFO "$i"
done <<< "$(find "$SRC_DIR/unica/patches" -mindepth 1 -maxdepth 1 -type d)"

while read -r i; do
    ((MODULES_COUNT+=1))
    PRINT_MODULE_INFO "$i"
done <<< "$(find "$SRC_DIR/target/$TARGET_CODENAME/patches" -mindepth 1 -maxdepth 1 -type d)"

exit 0
