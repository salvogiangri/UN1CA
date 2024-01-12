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

# shellcheck disable=SC1091,SC2001,SC2015

set -Ee

#[
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

SET_PROP()
{
    local PROP="$1"
    local VALUE="$2"
    local FILE="$3"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        PROP="$(echo -n "$PROP" | sed 's/=//g')"
        if grep -Fq "$PROP" "$FILE"; then
            echo "Deleting \"$PROP\" prop in $FILE" | sed "s.$WORK_DIR..g"
            sed -i "/^$PROP/d" "$FILE"
        fi
    else
        if grep -Fq "$PROP" "$FILE"; then
            local LINES

            echo "Replacing \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            LINES="$(sed -n "/^${PROP}\b/=" "$FILE")"
            for l in $LINES; do
                sed -i "$l c${PROP}=${VALUE}" "$FILE"
            done
        else
            echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            if ! grep -q "Added by scripts" "$FILE"; then
                echo "# Added by scripts/internal/apply_modules.sh" >> "$FILE"
            fi
            echo "$PROP=$VALUE" >> "$FILE"
        fi
    fi
}

READ_AND_APPLY_PROPS()
{
    local PARTITION
    local FILE

    for patch in "$1"/*.prop
    do
        PARTITION=$(basename "$patch" | sed 's/.prop//g')
        case "$PARTITION" in
            "odm")
                FILE="$WORK_DIR/odm/etc/build.prop"
                ;;
            "product")
                FILE="$WORK_DIR/product/etc/build.prop"
                ;;
            "system")
                FILE="$WORK_DIR/system/system/build.prop"
                ;;
            "system_ext")
                $TARGET_HAS_SYSTEM_EXT \
                    && FILE="$WORK_DIR/system_ext/etc/build.prop" \
                    || FILE="$WORK_DIR/system/system/system_ext/etc/build.prop"
                ;;
            "vendor")
                FILE="$WORK_DIR/vendor/build.prop"
                ;;
            "module")
                continue
                ;;
            *)
                echo "Unvalid file: \"$patch\""
                return 1
                ;;
        esac

        while read -r i; do
            [[ "$i" = "#"* ]] && continue
            [[ -z "$i" ]] && continue

            if [[ "$i" == *"delete" ]] || [[ -z "$(echo -n "$i" | cut -d "=" -f 2)" ]]; then
                SET_PROP "$(echo -n "$i" | cut -d " " -f 1)" --delete \
                    "$FILE"
            elif echo -n "$i" | grep -q "="; then
                SET_PROP "$(echo -n "$i" | cut -d "=" -f 1)" "$(echo -n "$i" | cut -d "=" -f 2)" \
                    "$FILE"
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
        exit 1
    fi

    if [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ]; then
        MODPATH="$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE"
    fi

    if [[ "$MODPATH" == *"unica/packages/knox"* ]]; then
        local SUBDIR
        SUBDIR=$(GEN_KNOX_SUBDIR)
        [ -z "$SUBDIR" ] && return 0
        MODPATH="$MODPATH/$SUBDIR"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        echo "File not found: $MODPATH/module.prop"
        exit 1
    elif [ -f "$MODPATH/disable" ]; then
        exit 0
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//" | sed "s/, /, @/")"
    fi

    echo "- Processing \"$MODNAME\" by @$MODAUTH"

    if ! grep -q '^SKIPUNZIP=1$' "$MODPATH/customize.sh" 2> /dev/null; then
        [ -d "$MODPATH/odm" ] && cp -a --preserve=all "$MODPATH/odm/"* "$WORK_DIR/odm"
        [ -d "$MODPATH/product" ] && cp -a --preserve=all "$MODPATH/product/"* "$WORK_DIR/product"
        [ -d "$MODPATH/system" ] && cp -a --preserve=all "$MODPATH/system/"* "$WORK_DIR/system/system"
        if $TARGET_HAS_SYSTEM_EXT; then
            [ -d "$MODPATH/system_ext" ] && cp -a --preserve=all "$MODPATH/system_ext/"* "$WORK_DIR/system_ext"
        else
            [ -d "$MODPATH/system_ext" ] && cp -a --preserve=all "$MODPATH/system_ext/"* "$WORK_DIR/system/system/system_ext"
        fi
        [ -d "$MODPATH/vendor" ] && cp -a --preserve=all "$MODPATH/vendor/"* "$WORK_DIR/vendor"
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
done <<< "$(find "$1" -mindepth 1 -maxdepth 1 -type d)"

exit 0
