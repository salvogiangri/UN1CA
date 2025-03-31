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
_CHECK_NON_EMPTY_PARAM()
{
    if [ ! "$2" ]; then
        echo -n -e '\033[0;31m' >&2

        local STACK_SIZE="${#FUNCNAME[@]}"
        if [[ "$STACK_SIZE" -gt "1" ]]; then
            echo -n "(" >&2
            if [[ "$STACK_SIZE" -gt "2" ]]; then
                echo -n "${BASH_SOURCE[2]//$SRC_DIR\//}:${BASH_LINENO[1]}:" >&2
            fi
            echo -n "${FUNCNAME[1]}) " >&2
        fi

        echo -n "$1 is not set!" >&2
        echo -e '\033[0m' >&2

        return 1
    fi

    return 0
}

_ECHO_STDERR()
{
    local TYPE="${1:?}"
    local MESSAGE="${2:?}"

    if [[ "$TYPE" == "W"* ]]; then
        echo -n -e '\033[0;33m' >&2
    elif [[ "$TYPE" == "E"* ]]; then
        echo -n -e '\033[0;31m' >&2
    fi

    local STACK_SIZE="${#FUNCNAME[@]}"
    if [[ "$STACK_SIZE" -gt "1" ]]; then
        echo -n "(" >&2
        if [[ "$STACK_SIZE" -gt "2" ]]; then
            echo -n "${BASH_SOURCE[2]//$SRC_DIR\//}:${BASH_LINENO[1]}:" >&2
        fi
        echo -n "${FUNCNAME[1]}) " >&2
    fi

    echo -n "$MESSAGE" >&2
    echo -e '\033[0m' >&2
}

_GET_PROP_FILES_PATH()
{
    local PARTITION="$1"
    local FILES

    if _IS_VALID_PARTITION_NAME "$PARTITION"; then
        case "$PARTITION" in
            "system")
                FILES="$WORK_DIR/system/system/build.prop"
                ;;
            "vendor")
                FILES="$WORK_DIR/vendor/default.prop
                    $WORK_DIR/vendor/build.prop"
                ;;
            "product")
                FILES="$WORK_DIR/product/etc/build.prop"
                ;;
            "system_ext")
                FILES="$WORK_DIR/system_ext/etc/build.prop
                    $WORK_DIR/system/system/system_ext/etc/build.prop"
                ;;
            "odm")
                FILES="$WORK_DIR/odm/etc/build.prop"
                ;;
            "vendor_dlkm")
                FILES="$WORK_DIR/vendor_dlkm/etc/build.prop
                    $WORK_DIR/vendor/vendor_dlkm/etc/build.prop"
                ;;
            "odm_dlkm")
                FILES="$WORK_DIR/vendor/odm_dlkm/etc/build.prop"
                ;;
            "system_dlkm")
                FILES="$WORK_DIR/system_dlkm/etc/build.prop
                    $WORK_DIR/system/system/system_dlkm/etc/build.prop"
                ;;
        esac
    else
        # https://android.googlesource.com/platform/system/core/+/refs/tags/android-15.0.0_r1/init/property_service.cpp#1214
        FILES="$WORK_DIR/system/system/build.prop
            $WORK_DIR/system_ext/etc/build.prop
            $WORK_DIR/system/system/system_ext/etc/build.prop
            $WORK_DIR/system_dlkm/etc/build.prop
            $WORK_DIR/system/system/system_dlkm/etc/build.prop
            $WORK_DIR/vendor/default.prop
            $WORK_DIR/vendor/build.prop
            $WORK_DIR/vendor_dlkm/etc/build.prop
            $WORK_DIR/vendor/vendor_dlkm/etc/build.prop
            $WORK_DIR/vendor/odm_dlkm/etc/build.prop
            $WORK_DIR/odm/etc/build.prop
            $WORK_DIR/product/etc/build.prop"
    fi

    echo "${FILES// }"
}

_GET_PROP_LOCATION()
{
    local FILES
    FILES="$(_GET_PROP_FILES_PATH "${1:?}")"

    if _IS_VALID_PARTITION_NAME "${1:?}"; then
        shift
    fi

    local PROP="${1:?}"
    # shellcheck disable=SC2116
    for f in $(echo "$FILES"); do
        grep -l "^$PROP=" "$f" 2> /dev/null || true
    done
}

_GET_SELINUX_LABEL()
{
    local PARTITION="${1:?}"
    local FILE="${2:?}"
    local FC_FILE

    case "$PARTITION" in
        "product")
            FC_FILE="$WORK_DIR/product/etc/selinux/product_file_contexts"
            ;;
        "vendor")
            FC_FILE="$WORK_DIR/vendor/etc/selinux/vendor_file_contexts"
            ;;
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FC_FILE="$WORK_DIR/system_ext/etc/selinux/system_ext_file_contexts"
            else
                FC_FILE="$WORK_DIR/system/system/system_ext/etc/selinux/system_ext_file_contexts"
            fi
            ;;
        *)
            FC_FILE="$WORK_DIR/system/system/etc/selinux/plat_file_contexts"
            ;;
    esac

    if [[ "${FILE:0:1}" != "/" ]]; then
        FILE="/$FILE"
    fi

    local LABEL="u:object_r:system_file:s0"
    while IFS= read -r l; do
        l="$(tr -s "\t" " " <<< "$l")"
        if [[ "$FILE" =~ ^$(cut -d " " -f 1 <<< "$l")$ ]]; then
            LABEL="$(cut -d " " -f 2 <<< "$l")"
            break
        fi
    done <<< "$(tac "$FC_FILE" 2> /dev/null)"

    echo "$LABEL"
}

_HANDLE_SPECIAL_CHARS()
{
    local STRING="${1:?}"

    STRING="${STRING//\./\\.}"
    STRING="${STRING//\+/\\+}"
    STRING="${STRING//\[/\\[}"
    STRING="${STRING//\]/\\]}"
    STRING="${STRING//\*/\\*}"

    echo "$STRING"
}

_IS_VALID_PARTITION_NAME()
{
    local PARTITION="$1"
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#131
    [[ "$PARTITION" == "system" ]] || [[ "$PARTITION" == "vendor" ]] || [[ "$PARTITION" == "product" ]] || \
        [[ "$PARTITION" == "system_ext" ]] || [[ "$PARTITION" == "odm" ]] || [[ "$PARTITION" == "vendor_dlkm" ]] || \
        [[ "$PARTITION" == "odm_dlkm" ]] || [[ "$PARTITION" == "system_dlkm" ]]
}
# ]

# ADD_TO_WORK_DIR <source> <partition> <file/dir> <user> <group> <mode> <label>
# Adds the supplied file/directory in work dir along with its entries in fs_config/file_context.
#
# `source` argument can be:
# - a full path
# - a string in the following format: "MODEL/CSC" (the folder MUST exist under `out/fw`)
# - a string with the product name of the desidered device's prebuilt blobs (the folder MUST exist under `prebuilts/samsung`)
#
# `user`/`group`/`mode`/`label`/ arguments can be omitted as long as the respective entry is present in `source`/fs_config and `source`/file_context.
ADD_TO_WORK_DIR()
{
    _CHECK_NON_EMPTY_PARAM "SOURCE" "$1"
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$2"
    _CHECK_NON_EMPTY_PARAM "FILE" "$3"

    local SOURCE="$1"
    local PARTITION="$2"
    local FILE="$3"
    local USER="$4"
    local GROUP="$5"
    local MODE="$6"
    local LABEL="$7"

    if [ ! -d "$SOURCE" ]; then
        if [ "$(cut -d "/" -f 2 -s <<< "$SOURCE")" ]; then
            SOURCE="$FW_DIR/$(cut -d "/" -f 1 <<< "$SOURCE")_$(cut -d "/" -f 2 <<< "$SOURCE")"
        else
            SOURCE="$SRC_DIR/prebuilts/samsung/$SOURCE"
        fi
    fi

    if [ ! -d "$SOURCE" ]; then
        _ECHO_STDERR ERR "Folder not found: ${SOURCE//$SRC_DIR\//}"
        return 1
    fi

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        _ECHO_STDERR ERR "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    while [[ "${FILE:0:1}" == "/" ]]; do
        FILE="${FILE:1}"
    done

    local SOURCE_FILE="$SOURCE"
    local TARGET_FILE="$WORK_DIR"
    if [[ "$PARTITION" == "system_ext" ]]; then
        if [ -d "$SOURCE/system_ext" ]; then
            SOURCE_FILE+="/system_ext/$FILE"
        elif [ -d "$SOURCE/system/system/system_ext" ]; then
            SOURCE_FILE+="/system/system/system_ext/$FILE"
        else
            SOURCE_FILE+="/system/system_ext/$FILE"
        fi

        if $TARGET_HAS_SYSTEM_EXT; then
            TARGET_FILE+="/system_ext/$FILE"
        else
            PARTITION="system"
            FILE="system/system_ext/$FILE"
            TARGET_FILE+="/system/$FILE"
        fi
    elif [[ "$PARTITION" == "system" ]]; then
        if [ -d "$SOURCE/system/system" ]; then
            SOURCE_FILE+="/system/$FILE"
            TARGET_FILE+="/system/$FILE"
        else
            SOURCE_FILE+="/system/${FILE//system\//}"
            TARGET_FILE+="/system/system/${FILE//system\//}"
        fi
    else
        SOURCE_FILE+="/$PARTITION/$FILE"
        TARGET_FILE+="/$PARTITION/$FILE"
    fi

    if [ ! -e "$SOURCE_FILE" ] && [ ! -L "$SOURCE_FILE" ]; then
        if [ -e "$SOURCE_FILE.00" ]; then
            mkdir -p "$(dirname "$TARGET_FILE")"
            cat "$SOURCE_FILE."* > "$TARGET_FILE"
        else
            _ECHO_STDERR ERR "File not found: ${SOURCE_FILE//$SRC_DIR\//}"
            return 1
        fi
    else
        if [ ! -d "$SOURCE_FILE" ]; then
            mkdir -p "$(dirname "$TARGET_FILE")"
        else
            mkdir -p "$TARGET_FILE"
        fi
        cp -a -T "$SOURCE_FILE" "$TARGET_FILE"
    fi

    local ENTRY="${TARGET_FILE//$WORK_DIR\//}"
    [[ "$PARTITION" == "system" ]] && ENTRY="${ENTRY//system\/system\//system/}"
    ENTRY="${ENTRY%/.}"

    if ! grep -q -F "$ENTRY " "$WORK_DIR/configs/fs_config-$PARTITION" 2> /dev/null; then
        if [ "$USER" ] && [ "$GROUP" ] && [ "$MODE" ]; then
            echo "$ENTRY $USER $GROUP $MODE capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
        elif grep -q -F "$ENTRY " "$SOURCE/fs_config-$PARTITION" 2> /dev/null; then
            grep -F "$ENTRY " "$SOURCE/fs_config-$PARTITION" >> "$WORK_DIR/configs/fs_config-$PARTITION"
        else
            _ECHO_STDERR WARN "No fs_config entry found for \"$ENTRY\" in \"${SOURCE//$SRC_DIR\//}\". Using default values"

            USER=0
            GROUP=0
            MODE=644
            [[ "$PARTITION" == "vendor" ]] && GROUP=2000
            [ -d "$TARGET_FILE" ] && MODE=755

            echo "$ENTRY $USER $GROUP $MODE capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
        fi
    fi

    if ! grep -q -F "/$(_HANDLE_SPECIAL_CHARS "$ENTRY") " "$WORK_DIR/configs/file_context-$PARTITION" 2> /dev/null; then
        if [ "$LABEL" ]; then
            echo "/$(_HANDLE_SPECIAL_CHARS "$ENTRY") $LABEL" >> "$WORK_DIR/configs/file_context-$PARTITION"
        elif grep -q -F "/$(_HANDLE_SPECIAL_CHARS "$ENTRY") " "$SOURCE/file_context-$PARTITION" 2> /dev/null; then
            grep -F "/$(_HANDLE_SPECIAL_CHARS "$ENTRY") " "$SOURCE/file_context-$PARTITION" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            _ECHO_STDERR WARN "No file_context entry found for \"$ENTRY\" in \"${SOURCE//$SRC_DIR\//}\". Using default value"

            LABEL="$(_GET_SELINUX_LABEL "$PARTITION" "/$ENTRY")"

            echo "/$(_HANDLE_SPECIAL_CHARS "$ENTRY") $LABEL" >> "$WORK_DIR/configs/file_context-$PARTITION"
        fi
    fi

    if [ -d "$TARGET_FILE" ]; then
        local FILES
        FILES="$(find "${SOURCE_FILE%/.}")"
        FILES="${FILES//$SOURCE\//}"
        [[ "$PARTITION" == "system" ]] && FILES="${FILES//system\/system\//system/}"
        $TARGET_HAS_SYSTEM_EXT || FILES="${FILES//system_ext\//system/system_ext/}"

        # shellcheck disable=SC2116
        for f in $(echo "$FILES"); do
            _IS_VALID_PARTITION_NAME "$f" && continue

            if ! grep -q -F "$f " "$WORK_DIR/configs/fs_config-$PARTITION" 2> /dev/null; then
                if grep -q -F "$f " "$SOURCE/fs_config-$PARTITION" 2> /dev/null; then
                    grep -F "$f " "$SOURCE/fs_config-$PARTITION" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                else
                    _ECHO_STDERR WARN "No fs_config entry found for \"$f\" in \"${SOURCE//$SRC_DIR\//}\". Using default values"

                    USER=0
                    GROUP=0
                    MODE=644
                    [[ "$PARTITION" == "vendor" ]] && GROUP=2000
                    if [ -d "$SOURCE/$f" ] || [ -d "$SOURCE/system/$f" ] || [ -d "$SOURCE/${f//system\//}" ]; then
                        MODE=755
                    fi

                    echo "$f $USER $GROUP $MODE capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                fi
            fi

            if ! grep -q -F "/$(_HANDLE_SPECIAL_CHARS "$f") " "$WORK_DIR/configs/file_context-$PARTITION" 2> /dev/null; then
                if grep -q -F "/$(_HANDLE_SPECIAL_CHARS "$f") " "$SOURCE/file_context-$PARTITION" 2> /dev/null; then
                    grep -F "/$(_HANDLE_SPECIAL_CHARS "$f") " "$SOURCE/file_context-$PARTITION" >> "$WORK_DIR/configs/file_context-$PARTITION"
                else
                    _ECHO_STDERR WARN "No file_context entry found for \"$f\" in \"${SOURCE//$SRC_DIR\//}\". Using default value"

                    LABEL="$(_GET_SELINUX_LABEL "$PARTITION" "/$f")"

                    echo "/$(_HANDLE_SPECIAL_CHARS "$f") $LABEL" >> "$WORK_DIR/configs/file_context-$PARTITION"
                fi
            fi
        done
    else
        local TMP="${TARGET_FILE%/.}"
        TMP="$(dirname "${TMP//$WORK_DIR\//}")"
        [[ "$PARTITION" == "system" ]] && TMP="${TMP//system\/system\//system/}"

        while [[ "$TMP" != "." ]]; do
            _IS_VALID_PARTITION_NAME "$TMP" && break

            if ! grep -q -F "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION" 2> /dev/null; then
                if grep -q -F "$TMP " "$SOURCE/fs_config-$PARTITION" 2> /dev/null; then
                    grep -F "$TMP " "$SOURCE/fs_config-$PARTITION" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                else
                    _ECHO_STDERR WARN "No fs_config entry found for \"$TMP\" in \"${SOURCE//$SRC_DIR\//}\". Using default values"

                    USER=0
                    GROUP=0
                    MODE=755
                    [[ "$PARTITION" == "vendor" ]] && GROUP=2000

                    echo "$TMP $USER $GROUP $MODE capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                fi
            fi

            if ! grep -q -F "/$(_HANDLE_SPECIAL_CHARS "$TMP") " "$WORK_DIR/configs/file_context-$PARTITION" 2> /dev/null; then
                if grep -q -F "/$(_HANDLE_SPECIAL_CHARS "$TMP") " "$SOURCE/file_context-$PARTITION" 2> /dev/null; then
                    grep -F "/$(_HANDLE_SPECIAL_CHARS "$TMP") " "$SOURCE/file_context-$PARTITION" >> "$WORK_DIR/configs/file_context-$PARTITION"
                else
                    _ECHO_STDERR WARN "No file_context entry found for \"$TMP\" in \"${SOURCE//$SRC_DIR\//}\". Using default values"

                    LABEL="$(_GET_SELINUX_LABEL "$PARTITION" "/$TMP")"

                    echo "/$(_HANDLE_SPECIAL_CHARS "$TMP") $LABEL" >> "$WORK_DIR/configs/file_context-$PARTITION"
                fi
            fi

            TMP="$(dirname "$TMP")"
        done
    fi

    return 0
}

# DECODE_APK <apk/jar>
# Same usage as `run_cmd apktool d <apk/jar>`.
# APK/JAR path MUST not be full and match an existing file inside work_dir.
DECODE_APK()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1"

    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        "$SRC_DIR/scripts/apktool.sh" d "$1"
        return $?
    fi

    return 0
}

# DELETE_FROM_WORK_DIR "<partition>" "<file/dir>"
# Deletes the supplied file/directory from work dir along with its entries in fs_config/file_context.
DELETE_FROM_WORK_DIR()
{
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$1"
    _CHECK_NON_EMPTY_PARAM "FILE" "$2"

    local PARTITION="$1"
    local FILE="$2"

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        echo "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    while [[ "${FILE:0:1}" == "/" ]]; do
        FILE="${FILE:1}"
    done

    if ! $TARGET_HAS_SYSTEM_EXT && [[ "$PARTITION" == "system_ext" ]]; then
        PARTITION="system"
        FILE="system/system_ext/$FILE"
    fi

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

    if [ ! -e "$FILE_PATH" ] && [ ! -L "$FILE_PATH" ]; then
        _ECHO_STDERR WARN "File not found: ${FILE_PATH//$WORK_DIR/}"
        return 0
    fi

    local IS_DIR=false
    [ -d "$FILE_PATH" ] && IS_DIR=true

    echo "Deleting ${FILE_PATH//$WORK_DIR/}"
    rm -rf "$FILE_PATH"

    local PATTERN="${FILE//\//\\/}"
    [ "$PARTITION" != "system" ] && PATTERN="$PARTITION\/$PATTERN"
    sed -i "/^$PATTERN /d" "$WORK_DIR/configs/fs_config-$PARTITION"
    if $IS_DIR; then
        sed -i "/^$PATTERN\//d" "$WORK_DIR/configs/fs_config-$PARTITION"
    fi

    PATTERN="$(_HANDLE_SPECIAL_CHARS "$FILE")"
    PATTERN="${PATTERN//\\/\\\\}"
    PATTERN="${PATTERN//\//\\/}"
    [ "$PARTITION" != "system" ] && PATTERN="$PARTITION\/$PATTERN"
    sed -i "/^\/$PATTERN /d" "$WORK_DIR/configs/file_context-$PARTITION"
    if $IS_DIR; then
        sed -i "/^\/$PATTERN\//d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi

    if [[ "$FILE" == *".so" ]]; then
        # shellcheck disable=SC2013
        for f in $(grep -l "$(basename "$FILE")" "$WORK_DIR/system/system/etc/public.libraries"*.txt); do
            sed -i "/$(basename "$FILE")/d" "$f"
        done
    fi

    return 0
}

# DOWNLOAD_FILE "<url>" "<output path>"
# Downloads the file from the provided URL and stores it in the desidered output path.
DOWNLOAD_FILE()
{
    _CHECK_NON_EMPTY_PARAM "URL" "$1"
    _CHECK_NON_EMPTY_PARAM "OUTPUT" "$2"

    local URL="$1"
    local OUTPUT="$2"

    mkdir -p "$(dirname "$OUTPUT")"
    curl -L -# -o "$OUTPUT" "$URL"
    return $?
}

# GET_GALAXY_STORE_DOWNLOAD_URL "<package name>"
# Returns a URL to download the desidered app from Samsung servers.
GET_GALAXY_STORE_DOWNLOAD_URL()
{
    _CHECK_NON_EMPTY_PARAM "PACKAGE" "$1"

    local PACKAGE="$1"
    local DEVICES
    local OS
    local OUT

    # Galaxy S23 Ultra EUR_OPENX, EUX CSC
    DEVICES+=("deviceId=SM-S918B&mcc=262&mnc=01&csc=EUX")
    # Galaxy S23 Ultra CHN_OPENX, CHC CSC
    DEVICES+=("deviceId=SM-S9180&mcc=460&mnc=00&csc=CHC")

    OS="sdkVer="
    OS+="$(GET_PROP "system" "ro.build.version.sdk")"
    OS+="&oneUiVersion="
    OS+="$(GET_PROP "system" "ro.build.version.oneui")"

    for i in "${DEVICES[@]}"; do
        OUT="$(curl -L -s "https://vas.samsungapps.com/stub/stubDownload.as?appId=$PACKAGE&$i&$OS&extuk=0191d6627f38685f&pd=0")"
        if grep -q "Download URI Available" <<< "$OUT"; then
            grep "downloadURI" <<< "$OUT" | cut -d ">" -f 2 | sed -e 's/<!\[CDATA\[//g; s/\]\]//g'
            return $?
        fi
    done

    _ECHO_STDERR ERR "No download URI found for app \"$PACKAGE\""
    return 1
}

# GET_FLOATING_FEATURE_CONFIG "<config>"
# Returns the supplied config value.
GET_FLOATING_FEATURE_CONFIG()
{
    _CHECK_NON_EMPTY_PARAM "CONFIG" "$1"

    local CONFIG="$1"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [ ! -f "$FILE" ]; then
        _ECHO_STDERR ERR "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    grep -o -P "(?<=<$CONFIG>)[^<]+" "$FILE" 2> /dev/null
}

# GET_PROP "<partition>/<file>" "<prop>"
# Returns the supplied prop value, partition/file can be omitted.
GET_PROP()
{
    local FILES
    if [[ "$1" == *".prop" ]]; then
        FILES="$1"
        shift
    else
        FILES="$(_GET_PROP_FILES_PATH "$1")"
        if _IS_VALID_PARTITION_NAME "$1"; then
            shift
        fi
    fi

    _CHECK_NON_EMPTY_PARAM "PROP" "$1"

    local PROP="$1"
    # shellcheck disable=SC2002,SC2046,SC2116
    cat $(echo "$FILES") 2> /dev/null | sed -n "s/^$PROP=//p" | head -n 1
}

# HEX_PATCH "<file>" "<old pattern>" "<new pattern>"
# Applies the supplied hex patch to the desidered file.
HEX_PATCH()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1"
    _CHECK_NON_EMPTY_PARAM "FROM" "$2"
    _CHECK_NON_EMPTY_PARAM "TO" "$3"

    local FILE="$1"
    local FROM="$2"
    local TO="$3"

    if [ ! -f "$FILE" ]; then
        _ECHO_STDERR ERR "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    FROM="$(tr "[:upper:]" "[:lower:]" <<< "$FROM")"
    TO="$(tr "[:upper:]" "[:lower:]" <<< "$TO")"

    if xxd -p "$FILE" | tr -d "\n" | tr -d " " | grep -q "$TO"; then
        _ECHO_STDERR WARN "\"$TO\" already applied in ${FILE//$WORK_DIR/}"
        return 0
    fi

    if ! xxd -p "$FILE" | tr -d "\n" | tr -d " " | grep -q "$FROM"; then
        _ECHO_STDERR ERR "No \"$FROM\" match in ${FILE//$WORK_DIR/}"
        return 1
    fi

    echo "Patching \"$FROM\" to \"$TO\" in ${FILE//$WORK_DIR/}"
    xxd -p "$FILE" | tr -d "\n" | tr -d " " | sed "s/$FROM/$TO/" | xxd -r -p > "$FILE.tmp"
    mv "$FILE.tmp" "$FILE"

    return 0
}

# SET_FLOATING_FEATURE_CONFIG "<config>" "<value>"
# Sets the supplied config to the desidered value.
# "-d" or "--delete" can be passed as value to delete the config.
SET_FLOATING_FEATURE_CONFIG()
{
    _CHECK_NON_EMPTY_PARAM "CONFIG" "$1"
    _CHECK_NON_EMPTY_PARAM "VALUE" "$2"

    local CONFIG="$1"
    local VALUE="$2"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [ ! -f "$FILE" ]; then
        _ECHO_STDERR ERR "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    if grep -q "$CONFIG" "$FILE"; then
        if [[ "$VALUE" == "-d" ]] || [[ "$VALUE" == "--delete" ]]; then
            echo "Deleting \"$CONFIG\" config in /system/system/etc/floating_feature.xml"
            sed -i "/$CONFIG/d" "$FILE"
        else
            echo "Replacing \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
            sed -i "$(sed -n "/<${CONFIG}>/=" "$FILE") c\ \ \ \ <${CONFIG}>${VALUE}</${CONFIG}>" "$FILE"
        fi
    elif [[ "$VALUE" != "-d" ]] && [[ "$VALUE" != "--delete" ]]; then
        echo "Adding \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
        sed -i "/<\/SecFloatingFeatureSet>/d" "$FILE"
        if ! grep -q "Added by scripts" "$FILE"; then
            echo "    <!-- Added by scripts/utils/module_utils.sh -->" >> "$FILE"
        fi
        echo "    <${CONFIG}>${VALUE}</${CONFIG}>" >> "$FILE"
        echo "</SecFloatingFeatureSet>" >> "$FILE"
    fi

    return 0
}

# SET_PROP "<partition>" "<prop>" "<value>"
# Sets the supplied prop to the desidered value, partition name CANNOT be omitted.
# "-d" or "--delete" can be passed as value to delete the prop.
SET_PROP()
{
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$1"
    _CHECK_NON_EMPTY_PARAM "PROP" "$2"

    local PARTITION="$1"
    local PROP="$2"
    local VALUE="$3"

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        _ECHO_STDERR ERR "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    if [ "$(GET_PROP "$PARTITION" "$PROP")" ]; then
        local FILES
        FILES="$(_GET_PROP_LOCATION "$PARTITION" "$PROP")"
        # shellcheck disable=SC2116
        for f in $(echo "$FILES"); do
            if [[ "$VALUE" == "-d" ]] || [[ "$VALUE" == "--delete" ]]; then
                echo "Deleting \"$PROP\" prop in ${f//$WORK_DIR/}"
                sed -i "/^$PROP/d" "$f"
            else
                echo "Replacing \"$PROP\" prop with \"$VALUE\" in ${f//$WORK_DIR/}"

                local LINES
                LINES="$(sed -n "/^${PROP}\b/=" "$f")"
                for l in $LINES; do
                    sed -i "$l c${PROP}=${VALUE}" "$f"
                done
            fi
        done
    elif [[ "$VALUE" != "-d" ]] && [[ "$VALUE" != "--delete" ]]; then
        local FILE

        case "$PARTITION" in
            "system")
                FILE="$WORK_DIR/system/system/build.prop"
                ;;
            "system_ext")
                if $TARGET_HAS_SYSTEM_EXT; then
                    FILE="$WORK_DIR/system_ext/etc/build.prop"
                else
                    FILE="$WORK_DIR/system/system/system_ext/etc/build.prop"
                fi
                ;;
            "system_dlkm")
                FILE="$WORK_DIR/system_dlkm/etc/build.prop"
                ;;
            "vendor")
                FILE="$WORK_DIR/vendor/build.prop"
                ;;
            "vendor_dlkm")
                FILE="$WORK_DIR/vendor_dlkm/etc/build.prop"
                ;;
            "odm_dlkm")
                FILE="$WORK_DIR/vendor/odm_dlkm/etc/build.prop"
                ;;
            "odm")
                FILE="$WORK_DIR/odm/etc/build.prop"
                ;;
            "product")
                FILE="$WORK_DIR/product/etc/build.prop"
                ;;
        esac

        if [ ! -f "$FILE" ]; then
            _ECHO_STDERR WARN "File not found: ${FILE//$WORK_DIR/}"
            return 0
        fi

        echo "Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
        if ! grep -q "Added by scripts" "$FILE"; then
            echo "# Added by scripts/utils/module_utils.sh" >> "$FILE"
        fi
        echo "$PROP=$VALUE" >> "$FILE"
    fi

    return 0
}

# SET_PROP_IF_DIFF "<partition>" "<prop>" "<value>"
# Calls SET_PROP if the current prop value does not match, partition name CANNOT be omitted.
SET_PROP_IF_DIFF()
{
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$1"
    _CHECK_NON_EMPTY_PARAM "PROP" "$2"
    _CHECK_NON_EMPTY_PARAM "EXPECTED" "$3"

    local PARTITION="$1"
    local PROP="$2"
    local EXPECTED="$3"

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        _ECHO_STDERR ERR "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    local CURRENT
    CURRENT="$(GET_PROP "$PARTITION" "$PROP")"
    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || SET_PROP "$PARTITION" "$PROP" "$EXPECTED"
}
