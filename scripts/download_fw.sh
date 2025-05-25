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

DOWNLOAD_FIRMWARE()
{
    local PDR
    PDR="$(pwd)"

    cd "$ODIN_DIR"
    if [ "$i" == "$SOURCE_FIRMWARE" ]; then
        # Special handling for source firmware - download from the specified URL
        mkdir -p "$ODIN_DIR/${MODEL}_${REGION}"
        echo "- Downloading source firmware from custom URL..."
        curl -s --retry 5 --retry-delay 5 "https://29-samfw.cloud/v2/IxJCDiMnNDAyLC8kFxYuPxIlBxwSNh4lFzssIDs2ByAzMUEgOzEUQDMQMCMBOyw/OzsHAjsALBEzMCAINC9BNiMRMxAzCBQ/OzsUQDMwHgASMAIQLjghPTs7HykNLzMUHicuFzUkQRAhCAIUFyUCGhcbFTk1ACwfDxYpJDsLBxY1BwI4EjA+Gi5ABkIeCzwGHgM8FCMkNDEjCxVACTghHzInDQYuFx8rIwAvJCFAMxE8EQY5NRshDjURPho0ES8kNRYhOR44LwsJEQc5NBsjKyEAPg4hAAYsLjgeLDQRHg4yJTMsMiUNKzwAPh8mGzk5FyUzDTUHQQEuByADISxBIwMnOUANQAokMzYCICMXPjkDFzA1CS8pDTsxHhwzQAZCOzEHHjMsNCsNMT4eODAeHgkvIxQjAwcEODEvLxcHPgMBAwgGDSwpPDskKRYXO0EIOAAhKTw/FD01OCBCJiceKyEILEAuFkEcNAghGyM2Hx4eMQI4PCUNFDwvNBQ8FywtNQcgFAEIKScjOAZCIwM0MQEWCBQeCyMdHiITEw==" -o "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip"
        
        echo "- Extracting firmware..."
        unzip -q "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip" -d "$ODIN_DIR/${MODEL}_${REGION}"
        rm -f "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip"
        
        touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded"
    elif [ "$i" == "$TARGET_FIRMWARE" ]; then
        # Special handling for target firmware - download from the specified URL
        mkdir -p "$ODIN_DIR/${MODEL}_${REGION}"
        echo "- Downloading target firmware from custom URL..."
        curl -s --retry 5 --retry-delay 5 "https://29-samfw.cloud/v2/IxJCDiMnLhEjBy8xAwgIBi8sKR4uMR4lFzssIDs2ByAzMUEgOzEUQDMQMCMBOyw/AwgHKy8lKSkeFwgwNREUFzgkCDEvBy47DUACKQ8XLA0vJDwfAQcsCh4nMz0eNiwOMhdBBTIXBkEzLzM2NTgpCBInLA0JLwI2AzYvCTIWKSA4MR8GEgdBJi84BkIeCzwGHgM8FCMkNDEjCxVACTghHzInDQYuFx8rIwAvJCFAMxE8EQY5NRshDjURPho0ES8kNRYhOR44LwsJEQc5NBsjKyEAPg4hAAYsLjgeLDQRHg4yJTMsMiUNKzwAPh8mGzk5FyUzDTUHQQEuByADISxBIwMnOUANQAokMzYCICMXPjkDFzA1CS8pDTsxHhwzQAZCOzEHHjMsNCsNMT4eODAeHgk7MTAjAy8nODFBFwMwPh4eAwgwMywpPDskIQgXCDsxOAAhKTw/FD01OCBCJgcvLDMDLz0DJzAaMxdBAjs2HwkeAAcgFycHHSEAOT8NFzsfOzgVMR4AHhwjOAZCIwM0MQEWCBQeCw05HjkTEw==" -o "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip"
        
        echo "- Extracting firmware..."
        unzip -q "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip" -d "$ODIN_DIR/${MODEL}_${REGION}"
        rm -f "$ODIN_DIR/${MODEL}_${REGION}/firmware.zip"
        
        touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded"
    else
        # Original download method for other firmwares
        { samfirm -m "$MODEL" -r "$REGION" -i "$IMEI" > /dev/null; } 2>&1 \
            && touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" \
            || exit 1
    fi
    
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
