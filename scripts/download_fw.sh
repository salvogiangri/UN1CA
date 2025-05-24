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

# shellcheck disable=SC2162

set -e

# [
GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$REGION/$MODEL/version.xml" \
        | grep latest | sed 's/^[^>]*>//' | sed 's/<.*//'
}

DOWNLOAD_AND_EXTRACT_FIRMWARE()
{
    local url="$1"
    echo "- Downloading firmware..."
    curl -s --retry 5 --retry-delay 5 "$url" -o "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip"
    
    echo "- Extracting firmware..."
    unzip -q "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip" -d "$ODIN_DIR/${MODEL}_${REGION}"
    rm -f "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip"
}

DOWNLOAD_FIRMWARE()
{
    local PDR
    PDR="$(pwd)"

    cd "$ODIN_DIR"
    mkdir -p "$ODIN_DIR/${MODEL}_${REGION}"
    
    if [ "$i" == "$SOURCE_FIRMWARE" ]; then
        # Source firmware download and extract
        DOWNLOAD_AND_EXTRACT_FIRMWARE "https://23-samfw.cloud/v2/IxJCDiMnNB8jFiASLzsNMC8vIEEvOx4lFzssIDs2ByAzMUEgOzEUQDMQMCMBOyw/LyQzPDQLNBQXOAc9IxcsHh4WIj8zCCMGLjENQC4WLjkhJzMwMzBBOC8wQTsJLykMDQAwJhIRISY7ByAeHjAvLRI2HwENLAcaLjAvBS8vLhwuByAWEiwpLSMbBkIjCyI/Iws8MQEWCDAeCw0xCREHOTQbIyshAD4OIQAGLC44Hiw0ER4OMiUzLDIlDSs8AD4fJhsGOg8HCkA8AywnCRc+Di8LBxAzBy4RDxYpKTwkHjUeBylCJgceIAM7ITgJNh4cAy8+AwMSMAMBAwgGDSw+By8vKSY7JDYGIztBPBcHIx0NMCwEMwc+ETwXIysPESw5JhsGEg0XOT80MC4IOy8pOAMDKSUuOy8/MxdBJx4bAgINOy4pOxchPy8ALywJAwdCJhYIQB4WFQYjFjw/IwM2Ew=="
    elif [ "$i" == "$TARGET_FIRMWARE" ]; then
        # Target firmware download and extract
        DOWNLOAD_AND_EXTRACT_FIRMWARE "https://23-samfw.cloud/v2/IxJCDiMnNDk0JzAaDSUCOiMvBzwyOx4lFzssIDs2ByAzMUEgOzEUJTMQMCMBOyw/EhshEjQxAi0SJAgGIycpGiEIIQcjJEEUEkA0FDI4PDABGzMBEhYNPzQAFQYhMTAMHxcGBzUDBxIzJB46M0AgCy87LCQ8OCFBPDYGOhcsQTYXBzs5IwcCMyYbOQAeCwgwHgs2JB4kDT8BFjQfLhEwGiEWBzA1AB0kITgeJS4nIRAyGyAKLhE+DDIABj8hOB4KHiUiMC4XIys8OCA5ND8UJTIAPiUyJy8wNAAvPzwAPisuJy8rLgQUCzIAMEImFiA1LgcgCjs2FDE7Bx4ROzYGIzIWLhYPCx4nEjYIBjJAIB4yLwofFwcgAw0xPhsmGwYDDTswJy8/FBYDMTAmOzExHwMDOwYeOyEmDSwhHDgxMTAjAy8nFwcpAx42MzwzAzMmIREHCwklAgI0GwZCLyUCITsALwkeJz4FMxYvLy87Hh4POAcCNDAIMSMxLw0NLykLHkACGxIXNAYmGzkGHiQNHSMDIgAeFg0G"
    else
        # Original download method for extra firmwares
        { samfirm -m "$MODEL" -r "$REGION" -i "$IMEI" > /dev/null; } 2>&1 \
            && touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" \
            || exit 1
    fi
    
    # Create .downloaded file with version info
    touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded"
    [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ] && {
        echo -n "$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "AP*" -exec basename {} \; | cut -d "_" -f 2)/"
        echo -n "$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "CSC*" -exec basename {} \; | cut -d "_" -f 3)/"
        echo -n "$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "CP*" -exec basename {} \; | cut -d "_" -f 2)"
    } >> "$ODIN_DIR/${MODEL}_${REGION}/.downloaded"

    echo ""
    cd "$PDR"
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
