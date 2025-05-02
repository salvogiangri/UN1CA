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

FRAMEWORK_DIR="$APKTOOL_DIR/bin/fw"

FORCE=false
PARTITION=""
FILE=""

INPUT_FILE=""
OUTPUT_PATH=""

BUILD()
{
    if [ ! -d "$OUTPUT_PATH" ]; then
        LOGE "Folder not found: ${OUTPUT_PATH//$SRC_DIR\//}"
        exit 1
    fi

    LOG "- Building ${INPUT_FILE//$WORK_DIR/}"

    # DEX format version might not be matching minSdkVersion, currently we handle
    # baksmali manually as apktool will by default use minSdkVersion when available
    # instead of the actual DEX format version used in the input apk
    if [ -d "$OUTPUT_PATH/smali" ]; then
        local DEX_API_LEVEL
        local DEX_FILENAME

        for f in "$OUTPUT_PATH/smali"*; do
            DEX_API_LEVEL="$(cat "$OUTPUT_PATH/../dex_api_version" 2> /dev/null)"

            # https://github.com/google/smali/blob/3.0.9/dexlib2/src/main/java/com/android/tools/smali/dexlib2/VersionMap.java#L55-L79
            if [ ! "$DEX_API_LEVEL" ] || [[ "$DEX_API_LEVEL" -gt "35" ]]; then
                LOGE "Unvalid DEX API level: $DEX_API_LEVEL"
                exit 1
            fi

            if [[ "$f" == *"smali" ]]; then
                DEX_FILENAME="classes.dex"
            else
                DEX_FILENAME="$(basename "${f//smali_/}").dex"
            fi

            EVAL "smali a -a \"$DEX_API_LEVEL\" -j \"$(nproc)\" -o \"$OUTPUT_PATH/$DEX_FILENAME\" \"$f\"" &
        done

        # shellcheck disable=SC2046
        wait $(jobs -p) || exit 1
    fi

    # Copy original META-INF
    mkdir -p "$OUTPUT_PATH/build/apk"
    cp -a "$OUTPUT_PATH/original/META-INF" "$OUTPUT_PATH/build/apk/META-INF"

    # Build APK with --shorten-resource-paths (https://developer.android.com/tools/aapt2#optimize_options)
    EVAL "apktool b -j \"$(nproc)\" -p \"$FRAMEWORK_DIR\" -srp \"$OUTPUT_PATH\"" || exit 1

    [ -f "$OUTPUT_PATH/classes.dex" ] && rm "$OUTPUT_PATH/"*.dex

    local FILE_NAME
    FILE_NAME="$(basename "$INPUT_FILE")"

    if [[ "$INPUT_FILE" == *".apk" ]]; then
        local CERT_PREFIX="aosp"
        $ROM_IS_OFFICIAL && CERT_PREFIX="unica"

        LOG "- Signing ${INPUT_FILE//$WORK_DIR/}"
        EVAL "signapk \"$SRC_DIR/security/${CERT_PREFIX}_platform.x509.pem\" \"$SRC_DIR/security/${CERT_PREFIX}_platform.pk8\" \"$OUTPUT_PATH/dist/$FILE_NAME\" \"$OUTPUT_PATH/dist/temp.apk\"" || exit 1
        mv -f "$OUTPUT_PATH/dist/temp.apk" "$OUTPUT_PATH/dist/$FILE_NAME"
    else
        LOG "- Zipaligning ${INPUT_FILE//$WORK_DIR/}"
        EVAL "zipalign -p 4 \"$OUTPUT_PATH/dist/$FILE_NAME\" \"$OUTPUT_PATH/dist/temp\"" || exit 1
        mv -f "$OUTPUT_PATH/dist/temp" "$OUTPUT_PATH/dist/$FILE_NAME"
    fi

    mkdir -p "$(dirname "$INPUT_FILE")"
    mv -f "$OUTPUT_PATH/dist/$FILE_NAME" "$INPUT_FILE"
    rm -rf "$OUTPUT_PATH/build" && rm -rf "$OUTPUT_PATH/dist"

    if [ -d "${INPUT_FILE%/*}/oat" ]; then
        DELETE_FROM_WORK_DIR "$PARTITION" "${FILE%/*}/oat"
    fi
    if [ -f "${INPUT_FILE%/*}/$FILE_NAME.prof" ]; then
        DELETE_FROM_WORK_DIR "$PARTITION" "${FILE%/*}/$FILE_NAME.prof"
    fi
    if [ -f "${INPUT_FILE%/*}/$FILE_NAME.bprof" ]; then
        DELETE_FROM_WORK_DIR "$PARTITION" "${FILE%/*}/$FILE_NAME.bprof"
    fi
}

DECODE()
{
    if [ ! -f "$INPUT_FILE" ]; then
        LOGE "File not found: ${INPUT_FILE//$WORK_DIR/}"
        exit 1
    elif [ -d "$OUTPUT_PATH" ]; then
        if $FORCE; then
            rm -rf "$OUTPUT_PATH"
        else
            LOGE "Output directory already exists (${OUTPUT_PATH//$SRC_DIR\//}). Use --force flag if you want to overwrite it."
            exit 1
        fi
    fi

    if [[ "$(READ_BYTES_AT "$INPUT_FILE" "0" "4")" != "04034b50" ]]; then
        LOGE "File not valid: ${INPUT_FILE//$WORK_DIR/}"
        exit 1
    fi

    LOG "- Decoding ${INPUT_FILE//$WORK_DIR/}"
    EVAL "apktool d -j \"$(nproc)\" -o \"$OUTPUT_PATH\" -p \"$FRAMEWORK_DIR\" -s \"$INPUT_FILE\"" || exit 1

    # DEX format version might not be matching minSdkVersion, currently we handle
    # baksmali manually as apktool will by default use minSdkVersion when available
    # instead of the actual DEX format version used in the input apk
    if [ -f "$OUTPUT_PATH/classes.dex" ]; then
        local DEX_API_LEVEL
        local SMALI_OUT

        for f in "$OUTPUT_PATH/"*.dex; do
            DEX_API_LEVEL="$(DEX_TO_API "$f")"
            [ "$DEX_API_LEVEL" ] || exit 1
            echo -n "$DEX_API_LEVEL" > "$OUTPUT_PATH/../dex_api_version"

            if [[ "$f" == *"classes.dex" ]]; then
                SMALI_OUT="smali"
            else
                SMALI_OUT="smali_$(basename "${f//.dex/}")"
            fi

            # Disassemble DEX file with the following flags:
            # - Disabled synthetic accessors comments
            # - Disabled debug info
            # - Use .locals directive instead of the .registers one
            # - Use a sequential numbering scheme for labels
            EVAL "baksmali d -a \"$DEX_API_LEVEL\" --ac false --di false -j \"$(nproc)\" -l -o \"$OUTPUT_PATH/$SMALI_OUT\" --sl \"$f\"" &
        done

        # shellcheck disable=SC2046
        wait $(jobs -p) || exit 1

        rm -f "$OUTPUT_PATH/"*.dex
    fi

    # https://github.com/iBotPeaches/Apktool/issues/3615
    if [[ "$INPUT_FILE" == *"framework.jar" ]]; then
        if unzip -l "$INPUT_FILE" | grep -q "debian.mime.types"; then
            unzip -q "$INPUT_FILE" "res/*" -d "$OUTPUT_PATH/unknown"
        fi
    fi
}

# https://github.com/google/smali/blob/3.0.9/dexlib2/src/main/java/com/android/tools/smali/dexlib2/VersionMap.java#L36-L53
DEX_TO_API()
{
    local DEX_FILE="$1"

    local DEX_VERSION
    DEX_VERSION="$(READ_BYTES_AT "$DEX_FILE" "6" "1")"

    local API
    case "$DEX_VERSION" in
        "35")
            API="23"
            ;;
        "37")
            API="25"
            ;;
        "38")
            API="27"
            ;;
        "39")
            API="29"
            ;;
        "40")
            API="34"
            ;;
        "41")
            API="35"
            ;;
        *)
            LOGE "Unknown DEX format version ($DEX_VERSION) found in ${DEX_FILE//$APKTOOL_DIR\//}"
            ;;
    esac

    echo "$API"
}

PREPARE_SCRIPT()
{
    if [[ "$#" == 0 ]]; then
        PRINT_USAGE
        exit 1
    fi

    ACTION="$1"
    if [[ "$ACTION" != "decode" ]] && [[ "$ACTION" != "d" ]] && \
            [[ "$ACTION" != "build" ]] && [[ "$ACTION" != "b" ]]; then
        PRINT_USAGE
        exit 1
    fi

    shift

    if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
        FORCE=true
        shift
    fi

    PARTITION="$1"
    if [ ! "$PARTITION" ]; then
        PRINT_USAGE
        exit 1
    elif ! IS_VALID_PARTITION_NAME "$PARTITION"; then
        LOGE "\"$PARTITION\" is not a valid partition name"
        exit 1
    fi

    shift

    if [ ! "$1" ]; then
        PRINT_USAGE
        exit 1
    fi

    FILE="$1"
    while [[ "${FILE:0:1}" == "/" ]]; do
        FILE="${FILE:1}"
    done

    local FILE_PATH="$WORK_DIR"
    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH+="/system_ext"
            else
                FILE_PATH+="/system/system/system_ext"
            fi
            ;;
        *)
            FILE_PATH+="/$PARTITION"
            ;;
    esac
    FILE_PATH+="/$FILE"

    INPUT_FILE="$FILE_PATH"
    OUTPUT_PATH="$APKTOOL_DIR/$PARTITION/${FILE//system\//}"
}

PRINT_USAGE()
{
    echo "Usage: apktool d[ecode]/b[uild] [options] <partition> <file>" >&2
    echo " -f, --force : Force delete output directory" >&2
}
# ]

ACTION=""

PREPARE_SCRIPT "$@"

if [ ! -d "$FRAMEWORK_DIR" ]; then
    if [ -f "$WORK_DIR/system/system/framework/framework-res.apk" ]; then
        LOG "- Installing framework-res.apk"
        EVAL "apktool if -p \"$FRAMEWORK_DIR\" \"$WORK_DIR/system/system/framework/framework-res.apk\"" || exit 1
    else
        LOGE "File not found: /system/system/framework/framework-res.apk, please set up your work_dir first."
        exit 1
    fi
fi

case "$ACTION" in
    "d" | "decode")
        DECODE
        ;;
    "b" | "build")
        BUILD
        ;;
esac

exit 0
