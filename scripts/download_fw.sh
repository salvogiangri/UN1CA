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

# shellcheck disable=SC2162

# CMD_HELP Downloads the Firmware needed for selected device.

set -e

# [
GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$REGION/$MODEL/version.xml" \
        | grep latest | sed 's/^[^>]*>//' | sed 's/<.*//'
}

DOWNLOAD_FIRMWARE() {
    local PDR
    PDR="$(pwd)"

    cd "$ODIN_DIR" || { echo "Failed to enter ODIN_DIR: $ODIN_DIR"; exit 1; }

    # Directory for firmware download
    local TARGET_DIR="${ODIN_DIR}/${MODEL}_${REGION}"

    # Ensure the target directory exists
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR" || { echo "Failed to create directory: $TARGET_DIR"; exit 1; }
    fi

    # Determine whether to use -s or -i flag based on the length of $IMEI
    local SAMLOADER_FLAG
    if [ "${#IMEI}" -eq 11 ]; then
        SAMLOADER_FLAG="-s $IMEI"
    else
        SAMLOADER_FLAG="-i $IMEI"
    fi

    # Run samloader and check for success
    echo "Downloading firmware for $MODEL in region $REGION..."
    if ! samloader -m "$MODEL" -r "$REGION" $SAMLOADER_FLAG download -O "$TARGET_DIR"; then
        echo "Firmware download failed."
        exit 1
    fi

    # Mark download as successful
    touch "$TARGET_DIR/.downloaded"

    # Find and unzip firmware zip
    local ZIP_FILE
    ZIP_FILE=$(find "$TARGET_DIR" -name "*.zip" | head -n 1)
    if [ -f "$ZIP_FILE" ]; then
        echo "Unzipping $ZIP_FILE..."
        unzip -q "$ZIP_FILE" -d "$TARGET_DIR" || { echo "Failed to unzip $ZIP_FILE"; exit 1; }
        rm "$ZIP_FILE"  # Optional: Remove the ZIP file after extracting
    else
        echo "No ZIP file found in $TARGET_DIR"
        exit 1
    fi

    # Write firmware details to .downloaded file
    {
        echo -n "$(find "$TARGET_DIR" -name "AP*" -exec basename {} \; | cut -d "_" -f 2)/"
        echo -n "$(find "$TARGET_DIR" -name "CSC*" -exec basename {} \; | cut -d "_" -f 3)/"
        echo -n "$(find "$TARGET_DIR" -name "CP*" -exec basename {} \; | cut -d "_" -f 2)"
    } >> "$TARGET_DIR/.downloaded"

    echo ""
    cd "$PDR" || exit
}


FIRMWARES=( "$SOURCE_FIRMWARE" "$TARGET_FIRMWARE" )
IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${SOURCE_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
IFS=':' read -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${TARGET_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
# ]

FORCE=false

while [ "$#" != 0 ]; do
    case "$1" in
        "-f" | "--force")
            FORCE=true
            ;;
        *)
            echo "Usage: download_fw [options]"
            echo " -f, --force : Force firmware download"
            exit 1
            ;;
    esac

    shift
done

mkdir -p "$ODIN_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)
    IMEI=$(echo -n "$i" | cut -d "/" -f 3)

    if [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
        [ -z "$(GET_LATEST_FIRMWARE)" ] && continue
        if [[ "$(GET_LATEST_FIRMWARE)" != "$(cat "$ODIN_DIR/${MODEL}_${REGION}/.downloaded")" ]]; then
            if $FORCE; then
                echo "- Updating $MODEL firmware with $REGION CSC..."
                rm -rf "$ODIN_DIR/${MODEL}_${REGION}" && DOWNLOAD_FIRMWARE
            else
                echo    "- $MODEL firmware with $REGION CSC already downloaded"
                echo    "  A newer version of this device's firmware is available."
                echo -e "  To download, clean your Odin firmwares directory or run this cmd with \"--force\"\n"
                continue
            fi
        else
            echo -e "- $MODEL firmware with $REGION CSC already downloaded\n"
            continue
        fi
    else
        echo "- Downloading $MODEL firmware with $REGION CSC..."
        rm -rf "$ODIN_DIR/${MODEL}_${REGION}" && DOWNLOAD_FIRMWARE
    fi
done

exit 0
