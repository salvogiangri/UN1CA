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

# CMD_HELP Usage: apktool d[ecode]/b[uild] <apk> (<apk>...)
# CMD_HELP APK/JAR path MUST not be full and match an existing file inside work_dir
# CMD_HELP Output files will be stored in ($APKTOOL_DIR)
# CMD_HELP Recompiled apk will be copied back to its original directory

set -eu
shopt -s nullglob

# [
PRINT_USAGE()
{
    echo "Usage: apktool d[ecode]/b[uild] <apk> (<apk>...)"
    echo "- APK/JAR path MUST not be full and match an existing file inside work_dir"
    echo "- Output files will be stored in ($APKTOOL_DIR)"
    echo "- Recompiled apk will be copied back to its original directory"
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

DO_DECOMPILE()
{
    local OUT_DIR="$1"
    local APK_PATH

    [[ "$OUT_DIR" != "/"* ]] && OUT_DIR="/$OUT_DIR"

    case "$OUT_DIR" in
        "/system/system_ext/"*)
            if $TARGET_HAS_SYSTEM_EXT; then
                APK_PATH="$WORK_DIR$(echo "$OUT_DIR" | sed 's/\/system\/system_ext/\/system_ext/')"
            else
                APK_PATH="$WORK_DIR/system$OUT_DIR"
            fi
            OUT_DIR="$(echo "$OUT_DIR" | sed 's/\/system\/system_ext/\/system_ext/')"
        ;;
        "/system_ext/"*)
            if $TARGET_HAS_SYSTEM_EXT; then
                APK_PATH="$WORK_DIR$OUT_DIR"
            else
                APK_PATH="$WORK_DIR/system/system$OUT_DIR"
            fi
            ;;
        "/system/system/"*)
            APK_PATH="$WORK_DIR$OUT_DIR"
            OUT_DIR="$(echo "$OUT_DIR" | sed 's/\/system\/system/\/system/')"
            ;;
        "/system/"*)
            APK_PATH="$WORK_DIR/system$OUT_DIR"
            ;;
        "/odm/"* | "/product/"* | "/system_dlkm/"* | "/vendor/"* | "/vendor_dlkm/"*)
            APK_PATH="$WORK_DIR$OUT_DIR"
            ;;
        *)
            echo "Unvalid path: $OUT_DIR"
            return 1
            ;;
    esac

    if [ ! -f "$APK_PATH" ]; then
        echo "File not found: $OUT_DIR"
        return 1
    elif [[ "$(xxd -p -l "4" "$APK_PATH")" != "504b0304" ]]; then
        echo "File not valid: $OUT_DIR"
        return 1
    fi

    if [[ "$APK_PATH" == *".jar" ]]; then
        API=( "-api" "$SOURCE_API_LEVEL" )
    fi

    echo "Decompiling $OUT_DIR"
    apktool -q d "${API[@]}" -b $FORCE -o "$APKTOOL_DIR$OUT_DIR" -p "$FRAMEWORK_DIR" -s "$APK_PATH"

    for f in "$APKTOOL_DIR$OUT_DIR/"*.dex
    do
        API="34"
        [[ "$(xxd -p -l "2" --skip "5" "$f")" == "3339" ]] && API="29"
        printf "$API" > "$APKTOOL_DIR$OUT_DIR/../dex_api_version"

        if [[ "$f" == *"classes.dex" ]]; then
            DIR_NAME="smali"
        else
            DIR_NAME="smali_$(basename ${f//.dex/})"
        fi

        baksmali d -a $API --ac false --di false -l -o "$APKTOOL_DIR$OUT_DIR/$DIR_NAME" --sl "$f"
        rm "$f"
    done

    # Workaround for U framework.jar
    if [[ "$APK_PATH" == *"framework.jar" ]]; then
        if unzip -l "$APK_PATH" | grep -q "debian.mime.types"; then
            unzip -q "$APK_PATH" "res/*" -d "$APKTOOL_DIR$OUT_DIR/unknown"
            sed -i \
                '/^doNotCompress/i \ \ res\/android.mime.types: 8\n\ \ res\/debian.mime.types: 8\n\ \ res\/vendor.mime.types: 8' \
                "$APKTOOL_DIR$OUT_DIR/apktool.yml"
        fi
    fi
}

DO_RECOMPILE()
{
    local IN_DIR="$1"
    local APK_PATH
    local CERT_PREFIX="aosp"
    $ROM_IS_OFFICIAL && CERT_PREFIX="unica"

    [[ "$IN_DIR" != "/"* ]] && IN_DIR="/$IN_DIR"

    case "$IN_DIR" in
        "/system/system_ext/"*)
            if $TARGET_HAS_SYSTEM_EXT; then
                APK_PATH="$WORK_DIR$(echo "$IN_DIR" | sed 's/\/system\/system_ext/\/system_ext/')"
            else
                APK_PATH="$WORK_DIR/system$IN_DIR"
            fi
            IN_DIR="$(echo "$IN_DIR" | sed 's/\/system\/system_ext/\/system_ext/')"
        ;;
        "/system_ext/"*)
            if $TARGET_HAS_SYSTEM_EXT; then
                APK_PATH="$WORK_DIR$IN_DIR"
            else
                APK_PATH="$WORK_DIR/system/system$IN_DIR"
            fi
            ;;
        "/system/system/"*)
            APK_PATH="$WORK_DIR$IN_DIR"
            IN_DIR="$(echo "$IN_DIR" | sed 's/\/system\/system/\/system/')"
            ;;
        "/system/"*)
            APK_PATH="$WORK_DIR/system$IN_DIR"
            ;;
        "/odm/"* | "/product/"* | "/system_dlkm/"* | "/vendor/"* | "/vendor_dlkm/"*)
            APK_PATH="$WORK_DIR$IN_DIR"
            ;;
        *)
            echo "Unvalid path: $IN_DIR"
            return 1
            ;;
    esac

    if [ ! -d "$APKTOOL_DIR$IN_DIR" ]; then
        echo "Folder not found: $IN_DIR"
        return 1
    fi

    local APK_NAME
    APK_NAME="$(basename "$APK_PATH")"

    echo "Recompiling $IN_DIR"

    for f in "$APKTOOL_DIR$IN_DIR/"*
    do
        [[ "$f" != *"smali"* ]] && continue

        API="34"
        [[ "$(cat "$APKTOOL_DIR$IN_DIR/../dex_api_version")" == "29" ]] && API="29"

        if [[ "$f" == *"smali" ]]; then
            DEX_FILE="classes.dex"
        else
            DEX_FILE="$(basename ${f/smali_//}).dex"
        fi

        smali a -a $API -o "$APKTOOL_DIR$IN_DIR/$DEX_FILE" "$f"
    done

    mkdir -p "$APKTOOL_DIR$IN_DIR/build/apk"
    cp -a --preserve=all "$APKTOOL_DIR$IN_DIR/original/META-INF" "$APKTOOL_DIR$IN_DIR/build/apk/META-INF"
    apktool -q b -p "$FRAMEWORK_DIR" -srp "$APKTOOL_DIR$IN_DIR"
    [[ -f "$APKTOOL_DIR$IN_DIR/classes.dex" ]] && rm "$APKTOOL_DIR$IN_DIR/"*.dex

    if [[ "$APK_PATH" == *".apk" ]]; then
        echo "Signing $IN_DIR"
        signapk "$SRC_DIR/unica/security/${CERT_PREFIX}_platform.x509.pem" "$SRC_DIR/unica/security/${CERT_PREFIX}_platform.pk8" \
            "$APKTOOL_DIR$IN_DIR/dist/$APK_NAME" "$APKTOOL_DIR$IN_DIR/dist/temp.apk" \
            && mv -f "$APKTOOL_DIR$IN_DIR/dist/temp.apk" "$APKTOOL_DIR$IN_DIR/dist/$APK_NAME"
    else
        echo "Zipaligning $IN_DIR"
        zipalign -p 4 "$APKTOOL_DIR$IN_DIR/dist/$APK_NAME" "$APKTOOL_DIR$IN_DIR/dist/temp" \
            && mv -f "$APKTOOL_DIR$IN_DIR/dist/temp" "$APKTOOL_DIR$IN_DIR/dist/$APK_NAME"
    fi

    mv -f "$APKTOOL_DIR$IN_DIR/dist/$APK_NAME" "$APK_PATH"
    rm -rf "$APKTOOL_DIR$IN_DIR/build" && rm -rf "$APKTOOL_DIR$IN_DIR/dist"

    if [ -d "${APK_PATH%/*}/oat" ]; then
        REMOVE_FROM_WORK_DIR "${APK_PATH%/*}/oat"
    fi
    if [ -f "${APK_PATH%/*}/$APK_NAME.prof" ]; then
        REMOVE_FROM_WORK_DIR "${APK_PATH%/*}/$APK_NAME.prof"
    fi
    if [ -f "${APK_PATH%/*}/$APK_NAME.bprof" ]; then
        REMOVE_FROM_WORK_DIR "${APK_PATH%/*}/$APK_NAME.bprof"
    fi
}

FRAMEWORK_DIR="$APKTOOL_DIR/bin/fw"
# ]

if [ ! -d "$FRAMEWORK_DIR" ]; then
    if [ -f "$WORK_DIR/system/system/framework/framework-res.apk" ]; then
        echo "Set up apktool env"
        apktool -q if -p "$FRAMEWORK_DIR" "$WORK_DIR/system/system/framework/framework-res.apk"
    else
        echo "Please set up your work_dir first."
        exit 1
    fi
fi

if [ "$#" == 0 ]; then
    PRINT_USAGE
    exit 1
fi

DECOMPILE=false
RECOMPILE=true

case "$1" in
    "d" | "decode")
        DECOMPILE=true
        ;;
    "b" | "build")
        RECOMPILE=true
        ;;
    *)
        PRINT_USAGE
        exit 1
        ;;
esac

shift

FORCE=""

if [[ "$1" == "-f" ]]|| [[ "$1" == "--force" ]]; then
    FORCE="-f"
    shift
fi

if [ "$#" == 0 ]; then
    PRINT_USAGE
    exit 1
fi

while [ "$#" != 0 ]; do
    if $DECOMPILE; then
        DO_DECOMPILE "$1"
    elif $RECOMPILE; then
        DO_RECOMPILE "$1"
    else
        PRINT_USAGE
        exit 1
    fi
    shift
done

exit 0
