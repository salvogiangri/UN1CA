#!/usr/bin/env bash
#
# Copyright (C) 2024 Salvo Giangreco
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
shopt -s nullglob

# [
GENERATE_OTA_INFO()
{
    local FILE="$1"
    local BUILD_INFO

    unzip -p "$FILE" "build_info.txt" > /dev/null || return 1
    BUILD_INFO="$(unzip -p "$FILE" "build_info.txt")"

    {
        echo    '    {'
        echo -n '      "datetime": '
        echo -n "$(echo "$BUILD_INFO" | grep "^timestamp" | cut -d "=" -f 2)"
        echo    ','
        echo -n '      "device": "'
        echo -n "$(echo "$BUILD_INFO" | grep "^device" | cut -d "=" -f 2)"
        echo    '",'
        echo -n '      "filename": "'
        echo -n "$(basename "$1")"
        echo    '",'
        echo -n '      "id": "'
        echo -n "$(sha256sum "$1" | cut -d " " -f 1)"
        echo    '",'
        echo -n '      "patch": "'
        echo -n "$(echo "$BUILD_INFO" | grep "^security_patch_version" | cut -d "=" -f 2)"
        echo    '",'
        echo -n '      "size": '
        echo -n "$(wc -c "$1" | cut -d " " -f 1)"
        echo    ','
        echo    '      "url": "INSERTURLHERE",'
        echo -n '      "version": "'
        echo -n "$(echo "$BUILD_INFO" | grep "^version" | cut -d "=" -f 2)"
        echo    '"'
        echo    '    },'
    } >> "$MANIFEST_FILE"
}

MANIFEST_FILE="$SRC_DIR/manifest.json"
# ]

if [ "$#" != 1 ]; then
    echo "Usage: generate_ota_manifest <path to zips>"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Folder not found: $1"
    exit 1
fi

if ! find "$1" -maxdepth 1 -type f | grep -q ".zip"; then
    echo "No update files found in $1"
    exit 1
fi

[ -f "$MANIFEST_FILE" ] && rm -f "$MANIFEST_FILE"
touch "$MANIFEST_FILE"
{
    echo '{'
    echo '  "response": ['
} >> "$MANIFEST_FILE"
for f in "$1/"*.zip
do
    echo "- $(basename "$f")"
    GENERATE_OTA_INFO "$f"
done
{
    echo '  ]'
    echo '}'
} >> "$MANIFEST_FILE"
sed -i '
    $x;$G;/\(.*\),/!H;//!{$!d
};  $!x;$s//\1/;s/^\n//' "$MANIFEST_FILE"

echo "Manifest saved in $MANIFEST_FILE"

exit 0
