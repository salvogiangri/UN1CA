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

set -Ee

# [
GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$REGION/$MODEL/version.xml" \
        | grep latest | sed 's/^[^>]*>//' | sed 's/<.*//'
}
#]

if [ "$#" != 1 ]; then
    echo "Usage: update_prebuilt_blobs <path>"
    exit 1
fi

if [ ! -d "$SRC_DIR/$1" ]; then
    echo "Folder not found: $SRC_DIR/$1"
    exit 1
fi

MODULE="$SRC_DIR/$1"
BLOBS=""
FIRMWARE=""

if [ -d "$MODULE/system" ]; then
    BLOBS+="$(find "$MODULE/system" -type f)"
    BLOBS="${BLOBS//$MODULE/system}"
fi
if [ -d "$MODULE/product" ]; then
    [[ "$BLOBS" ]] && BLOBS+=$'\n'
    BLOBS+="$(find "$MODULE/product" -type f)"
    BLOBS="${BLOBS//$MODULE\//}"
fi
if [ -d "$MODULE/vendor" ]; then
    [[ "$BLOBS" ]] && BLOBS+=$'\n'
    BLOBS+="$(find "$MODULE/vendor" -type f)"
    BLOBS="${BLOBS//$MODULE\//}"
fi
if [ -d "$MODULE/system_ext" ]; then
    [[ "$BLOBS" ]] && BLOBS+=$'\n'
    BLOBS+="$(find "$MODULE/system_ext" -type f)"
    BLOBS="${BLOBS//$MODULE\//}"
fi

case "$1" in
    "prebuilts/samsung/a52qnsxx")
        FIRMWARE="SM-A525F/SER/352938771234569"
        ;;
    "prebuilts/samsung/a52sxqxx")
        FIRMWARE="SM-A528B/BTU/352599501234566"
        ;;
    "prebuilts/samsung/a73xqxx")
        FIRMWARE="SM-A736B/XME/352828291234563"
        ;;
    "prebuilts/samsung/b5qxxx")
        FIRMWARE="SM-F731B/EUX/350929871234569"
        ;;
    "prebuilts/samsung/dm1qkdiw")
        FIRMWARE="SCG19/KDI/RFCW320SDNY"
        ;;
    "prebuilts/samsung/dm3qxxx")
        FIRMWARE="SM-S918B/EUX/350196551234562"
        ;;
    "prebuilts/samsung/e1qzcx")
        FIRMWARE="SM-S9210/CHC/356724910402671"
        ;;
    "prebuilts/samsung/gts9xxx")
        FIRMWARE="SM-X716B/EUX/353439961234567"
        ;;
    "prebuilts/samsung/r0qxxx")
        FIRMWARE="SM-S901E/INS/350999641234561"
        ;;
    "prebuilts/samsung/r9qxxx")
        FIRMWARE="SM-G990B/EUX/353718681234563"
        ;;
    "prebuilts/samsung/r11sxxx")
        FIRMWARE="SM-S711B/EUX/358615311234564"
        ;;
    "target/dm1q/patches/china")
        FIRMWARE="SM-S9110/TGY/RFCW2198XNF"
        ;;
    "target/dm2q/patches/china")
        FIRMWARE="SM-S9160/TGY/R5CW22FT58F"
        ;;
    "target/dm3q/patches/china")
        FIRMWARE="SM-S9180/TGY/R5CW613B3ME"
        ;;
    *)
        echo "Firmware not set for path $1"
        exit 1
        ;;
esac

MODEL=$(echo -n "$FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$FIRMWARE" | cut -d "/" -f 2)

[ -z "$(GET_LATEST_FIRMWARE)" ] && exit 1
if [[ "$(GET_LATEST_FIRMWARE)" == "$(cat "$MODULE/.current")" ]]; then
    echo "Nothing to do."
    exit 0
fi

echo -e "Updating $MODULE blobs\n"

export SOURCE_FIRMWARE="$FIRMWARE"
export TARGET_FIRMWARE="$FIRMWARE"
export SOURCE_EXTRA_FIRMWARES=""
export TARGET_EXTRA_FIRMWARES=""
"$SRC_DIR/scripts/download_fw.sh"
"$SRC_DIR/scripts/extract_fw.sh"

for i in $BLOBS; do
    if [[ "$i" == *[0-9] ]]; then
        i="${i%.*}"
    fi
    OUT="$MODULE/${i//system\/system\///system/}"

    [[ -e "$FW_DIR/${MODEL}_${REGION}/$i" ]] || continue

    if [[ "$(wc -c "$FW_DIR/${MODEL}_${REGION}/$i" | cut -d " " -f 1)" -gt "52428800" ]]; then
        rm "$OUT."*
        split -d -b 52428800 "$FW_DIR/${MODEL}_${REGION}/$i" "$OUT."
    else
        cp -a "$FW_DIR/${MODEL}_${REGION}/$i" "$OUT"
    fi
done

cp -a "$FW_DIR/${MODEL}_${REGION}/.extracted" "$MODULE/.current"

exit 0
