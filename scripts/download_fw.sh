#!/usr/bin/env bash
#
# Copyright (C) 2025 Salvo Giangreco
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

# [
source "$SRC_DIR/scripts/utils/build_utils.sh"
source "$TOOLS_DIR/../venv/bin/activate"

FORCE=false

FIRMWARES=()
MODEL=""
CSC=""
IMEI=""
SERIAL_NO=""
LATEST_FIRMWARE=""
ZIP_FILE=""

# Samsung Android OS build version scheme works as follows (eg. A528BXXU1DWA4):
# - A528B: Model number
# - XX: Region (XX = EUR_OPEN)
# - U: Firmware type (U = full update, S = security update)
# - 1: Rollback protection bit
# - D: Major OS version (D = 4th OS rollout)
# - W: Year (W = 2023)
# - A: Month (A = january)
# - 4: Incremental version
COMPARE_SEC_BUILD_VERSION()
{
    local FIRST="$1"
    local SECOND="$2"

    FIRST="$(cut -d "/" -f 1 -s <<< "$FIRST")"
    SECOND="$(cut -d "/" -f 1 -s <<< "$SECOND")"

    local FIRST_MAJOR="${FIRST:${#FIRST}-4:1}"
    local FIRST_YEAR="${FIRST:${#FIRST}-3:1}"
    local FIRST_MONTH="${FIRST:${#FIRST}-2:1}"
    local FIRST_INCREMENTAL="${FIRST:${#FIRST}-1:1}"

    local SECOND_MAJOR="${SECOND:${#SECOND}-4:1}"
    local SECOND_YEAR="${SECOND:${#SECOND}-3:1}"
    local SECOND_MONTH="${SECOND:${#SECOND}-2:1}"
    local SECOND_INCREMENTAL="${SECOND:${#SECOND}-1:1}"

    if [[ "$FIRST_MAJOR" < "$SECOND_MAJOR" ]]; then
        return 1
    fi
    if [[ "$FIRST_YEAR" < "$SECOND_YEAR" ]]; then
        return 1
    fi
    if [[ "$FIRST_MONTH" < "$SECOND_MONTH" ]]; then
        return 1
    fi
    if [[ "$FIRST_INCREMENTAL" < "$SECOND_INCREMENTAL" ]]; then
        return 1
    fi

    return 0
}

GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$CSC/$MODEL/version.xml" \
        | perl -nE 'say $1 if /<latest[^>]*>(.*?)<\/latest>/'
}

PARSE_FIRMWARE_STRING()
{
    if [ ! "$1" ]; then
        LOGE "Firmware value cannot be empty"
        exit 1
    fi

    MODEL="$(cut -d "/" -f 1 -s <<< "$1")"
    if [ ! "$MODEL" ]; then
        LOGE "No device model value found in \"$1\""
        exit 1
    fi

    CSC="$(cut -d "/" -f 2 -s <<< "$1")"
    if [ ! "$CSC" ]; then
        LOGE "No CSC value found in \"$1\""
        exit 1
    elif [[ "${#CSC}" != "3" ]]; then
        LOGE "CSC not valid in \"$1\": $CSC"
        exit 1
    fi

    local THIRD
    THIRD="$(cut -d "/" -f 3 -s <<< "$1")"
    if [ ! "$THIRD" ]; then
        LOGE "No IMEI/SN value found in \"$1\""
        exit 1
    elif [[ "${#THIRD}" == "11" ]] && [[ "$THIRD" == "R"* ]]; then
        SERIAL_NO="$THIRD"
    elif [[ "${#THIRD}" -ge "8" ]] && [[ "${#THIRD}" -le "15" ]] && [[ "$THIRD" =~ ^[+-]?[0-9]+$ ]]; then
        # Allow uncomplete IMEIs as samloader can generate them by providing the first 8 numbers (TAC)
        IMEI="$THIRD"
    else
        LOGE "No valid IMEI/SN in \"$1\": $THIRD"
        exit 1
    fi
}

PREPARE_SCRIPT()
{
    local EXTRA_FIRMWARES=()
    local IGNORE_SOURCE=false
    local IGNORE_TARGET=false

    while [ "$#" != 0 ]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--ignore-source" ]]; then
            IGNORE_SOURCE=true
        elif [[ "$1" == "--ignore-target" ]]; then
            IGNORE_TARGET=true
        elif [[ "$1" == "-"* ]]; then
            LOGE "Unknown option: $1"
            PRINT_USAGE
            exit 1
        else
            EXTRA_FIRMWARES+=("$1")
        fi

        shift
    done

    if ! $IGNORE_SOURCE; then
        _CHECK_NON_EMPTY_PARAM "SOURCE_FIRMWARE" "$SOURCE_FIRMWARE"
        FIRMWARES+=("$SOURCE_FIRMWARE")
        IFS=':' read -r -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
        if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${SOURCE_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if ! $IGNORE_TARGET; then
        _CHECK_NON_EMPTY_PARAM "TARGET_FIRMWARE" "$TARGET_FIRMWARE"
        FIRMWARES+=("$TARGET_FIRMWARE")
        IFS=':' read -r -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
        if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${TARGET_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if [ "${#EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        FIRMWARES+=("${EXTRA_FIRMWARES[@]}")
    fi
}

PRINT_USAGE()
{
    echo "Usage: download_fw [options] <firmware>" >&2
    echo " --ignore-source : Skip parsing source firmware flags" >&2
    echo " --ignore-target : Skip parsing target firmware flags" >&2
    echo " -f, --force : Force delete output directory" >&2
}
# ]

PREPARE_SCRIPT "$@"

for i in "${FIRMWARES[@]}"; do
    PARSE_FIRMWARE_STRING "$i"

    LATEST_FIRMWARE="$(GET_LATEST_FIRMWARE)"
    if [ ! "$LATEST_FIRMWARE" ]; then
        LOGE "Latest available firmware could not be fetched"
        exit 1
    fi

    LOG_STEP_IN "- Processing $MODEL firmware with $CSC CSC"
    LOG "- Downloaded firmware: $(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"
    LOG "- Extracted firmware: $(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)"
    LOG "- Latest available firmware: $LATEST_FIRMWARE"

    LOG_STEP_IN

    if ! $FORCE; then
        # Skip if firmware is extracted and equal/newer than the one in FUS
        if [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ] && \
                COMPARE_SEC_BUILD_VERSION "$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted")" "$LATEST_FIRMWARE"; then
            LOG "$(tput setaf 3)! This firmware has already been extracted$(tput sgr0)"
            LOG_STEP_OUT; LOG_STEP_OUT
            continue
        fi

        # Skip and print a warning if a newer firmware has been downloaded but not extracted yet
        if [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ] && [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ] && \
                ! COMPARE_SEC_BUILD_VERSION "$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)" "$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"; then
            LOG "$(tput setaf 3)! A newer firmware has been downloaded$(tput sgr0)"
            LOG_STEP_OUT; LOG_STEP_OUT
            continue
        fi

        # Skip if firmware has already been downloaded
        if [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ]; then
            if ! COMPARE_SEC_BUILD_VERSION "$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded")" "$LATEST_FIRMWARE"; then
                LOG "$(tput setaf 3)! A newer firmware is available for download$(tput sgr0)"
                LOG_STEP_OUT; LOG_STEP_OUT
                continue
            else
                LOG "$(tput setaf 3)! This firmware has already been downloaded$(tput sgr0)"
                LOG_STEP_OUT; LOG_STEP_OUT
                continue
            fi
        fi
    fi

    LOG "- Downloading firmware..."
    [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ] && rm -rf "$ODIN_DIR/${MODEL}_${CSC}"
    mkdir -p "$ODIN_DIR/${MODEL}_${CSC}"
    # shellcheck disable=SC2164
    # Anan's samloader stores its logs in the current working directory, let's move into OUT_DIR just for this time
    (
    cd "$OUT_DIR"
    samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download -O "$ODIN_DIR/${MODEL}_${CSC}" 1> /dev/null || exit 1
    )

    ZIP_FILE="$(find "$ODIN_DIR/${MODEL}_${CSC}" -name "*.zip" | sort -r | head -n 1)"
    if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
        LOGE "Download failed"
        exit 1
    fi

    LOG "- Extracting $(basename "$ZIP_FILE")..."
    EVAL "unzip -n \"$ZIP_FILE\" -d \"$ODIN_DIR/${MODEL}_${CSC}\" && rm -rf \"$ZIP_FILE\"" || exit 1

    echo -n "$LATEST_FIRMWARE" > "$ODIN_DIR/${MODEL}_${CSC}/.downloaded"

    LOG_STEP_OUT; LOG_STEP_OUT
done

deactivate

exit 0
