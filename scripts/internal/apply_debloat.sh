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

# shellcheck disable=SC1090,SC1091

set -e

# [
DO_DEBLOAT()
{
    local PARTITION="$1"
    local FILE="$2"

    local FILE_PATH="$WORK_DIR/$PARTITION/$FILE"
    if [ -e "$FILE_PATH" ]; then
        echo "Debloating /$PARTITION/$FILE"
        rm -rf "$FILE_PATH"

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

source "$SRC_DIR/unica/debloat.sh"
[ -f "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh" ] \
    && source "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh"
# ]

for f in $ODM_DEBLOAT; do
    DO_DEBLOAT "odm" "$f"
done
for f in $PRODUCT_DEBLOAT; do
    DO_DEBLOAT "product" "$f"
done
for f in $SYSTEM_DEBLOAT; do
    DO_DEBLOAT "system" "$f"
done
for f in $SYSTEM_EXT_DEBLOAT; do
    if $TARGET_HAS_SYSTEM_EXT; then
        DO_DEBLOAT "system_ext" "$f"
    else
        DO_DEBLOAT "system" "system/system_ext/$f"
    fi
done
for f in $VENDOR_DEBLOAT; do
    DO_DEBLOAT "vendor" "$f"
done

exit 0
