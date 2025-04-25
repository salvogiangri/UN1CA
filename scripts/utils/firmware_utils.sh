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
# ]

# COMPARE_SEC_BUILD_VERSION <string1> <string2>
# Returns whether or not `string1` build number is older than `string2`.
COMPARE_SEC_BUILD_VERSION()
{
    local FIRST="$1"
    local SECOND="$2"

    FIRST="$(cut -d "/" -f 1 -s <<< "$FIRST")"
    SECOND="$(cut -d "/" -f 1 -s <<< "$SECOND")"

    # Samsung Android OS build version scheme works as follows (eg. A528BXXU1DWA4):
    # - A528B: Model number
    # - XX: Region (XX = EUR_OPEN)
    # - U: Firmware type (U = full update, S = security update)
    # - 1: Rollback protection bit
    # - D: Major OS version (D = 4th OS rollout)
    # - W: Year (W = 2023)
    # - A: Month (A = january)
    # - 4: Incremental version
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

# GET_LATEST_FIRMWARE <model> <csc>
# Returns the latest available firmware for the supplied model & CSC in the following format: PDA/CSC/MODEM
GET_LATEST_FIRMWARE()
{
    _CHECK_NON_EMPTY_PARAM "MODEL" "$1" || return 1
    _CHECK_NON_EMPTY_PARAM "CSC" "$2" || return 1

    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$2/$1/version.xml" \
        | perl -nE 'say $1 if /<latest[^>]*>(.*?)<\/latest>/'
}

# PARSE_FIRMWARE_STRING <string>
# Parses the supplied string and stores each value in MODEL/CSC/IMEI/SERIAL_NO variables.
# - The supplied string must be in the following format: <MODEL>/<CSC>/<IMEI/SN>
# - IMEI/SN that matches the given model is required to download the firmware from FUS
PARSE_FIRMWARE_STRING()
{
    local STRING="$1"

    if [ ! "$STRING" ]; then
        LOGE "Firmware value cannot be empty"
        exit 1
    fi

    MODEL="$(cut -d "/" -f 1 -s <<< "$STRING")"
    if [ ! "$MODEL" ]; then
        LOGE "No device model value found in \"$STRING\""
        exit 1
    fi

    CSC="$(cut -d "/" -f 2 -s <<< "$STRING")"
    if [ ! "$CSC" ]; then
        LOGE "No CSC value found in \"$STRING\""
        exit 1
    elif [[ "${#CSC}" != "3" ]]; then
        LOGE "CSC not valid in \"$STRING\": $CSC"
        exit 1
    fi

    local THIRD
    THIRD="$(cut -d "/" -f 3 -s <<< "$STRING")"
    if [ ! "$THIRD" ]; then
        LOGE "No IMEI/SN value found in \"$STRING\""
        exit 1
    elif [[ "${#THIRD}" == "11" ]] && [[ "$THIRD" == "R"* ]]; then
        SERIAL_NO="$THIRD"
    elif [[ "${#THIRD}" -ge "8" ]] && [[ "${#THIRD}" -le "15" ]] && [[ "$THIRD" =~ ^[+-]?[0-9]+$ ]]; then
        # Allow uncomplete IMEIs as samloader can generate them by providing the first 8 numbers (TAC)
        IMEI="$THIRD"
    else
        LOGE "No valid IMEI/SN in \"$STRING\": $THIRD"
        exit 1
    fi
}
