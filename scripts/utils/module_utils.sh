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
_IS_VALID_PARTITION_NAME()
{
    local PARTITION="$1"
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#131
    [[ "$PARTITION" == "system" ]] || [[ "$PARTITION" == "vendor" ]] || [[ "$PARTITION" == "product" ]] || \
        [[ "$PARTITION" == "system_ext" ]] || [[ "$PARTITION" == "odm" ]] || [[ "$PARTITION" == "vendor_dlkm" ]] || \
        [[ "$PARTITION" == "odm_dlkm" ]] || [[ "$PARTITION" == "system_dlkm" ]] || false
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
                # TODO replace with `getprop ro.vndk.version <= 30`?
                if [ -f "$WORK_DIR/vendor/default.prop" ]; then
                    FILES="$WORK_DIR/vendor/default.prop"$'\n'
                fi
                FILES+="$WORK_DIR/vendor/build.prop"
                ;;
            "product")
                FILES="$WORK_DIR/product/etc/build.prop"
                ;;
            "system_ext")
                if $TARGET_HAS_SYSTEM_EXT; then
                    FILES="$WORK_DIR/system_ext/etc/build.prop"
                else
                    FILES="$WORK_DIR/system/system/system_ext/etc/build.prop"
                fi
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
    FILES=$(_GET_PROP_FILES_PATH "${1:?}")

    if _IS_VALID_PARTITION_NAME "${1:?}"; then
        shift
    fi

    local PROP="${1:?}"
    # shellcheck disable=SC2116
    for f in $(echo "$FILES"); do
        grep -l "^$PROP=" "$f" 2> /dev/null || true
    done
}

_GET_WORK_DIR_PARTITION_PATH()
{
    local PARTITION="${1:?}"
    _IS_VALID_PARTITION_NAME "$PARTITION" || return

    local PARTITION_PATH="$WORK_DIR"
    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                PARTITION_PATH+="/system/system/system_ext"
            else
                PARTITION_PATH+="/system_ext"
            fi
            ;;
        *)
            PARTITION_PATH+="/$PARTITION"
            ;;
    esac

    echo "$PARTITION_PATH"
}
# ]

# GET_FLOATING_FEATURE_CONFIG "<config>"
# Returns the supplied config value.
GET_FLOATING_FEATURE_CONFIG()
{
    local CONFIG="${1:?}"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    grep -o -P "(?<=<$CONFIG>)[^<]+" "$FILE" 2> /dev/null
}

# GET_PROP "<partition>/<file>" "<prop>"
# Returns the supplied prop value, partition/file can be omitted.
GET_PROP()
{
    local FILES
    if [[ "${1:?}" == *".prop" ]]; then
        FILES="$1"
        shift
    else
        FILES=$(_GET_PROP_FILES_PATH "${1:?}")
        if _IS_VALID_PARTITION_NAME "${1:?}"; then
            shift
        fi
    fi

    local PROP="${1:?}"
    # shellcheck disable=SC2002,SC2046,SC2116
    cat $(echo "$FILES") 2> /dev/null | sed -n "s/^$PROP=//p" | head -n 1
}

# HEX_PATCH <file> <old pattern> <new pattern>
# Applies the supplied hex patch to the desidered file.
HEX_PATCH()
{
    local FILE="${1:?}"
    local FROM="${2:?}"
    local TO="${3:?}"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    FROM="$(tr "[:upper:]" "[:lower:]" <<< "$FROM")"
    TO="$(tr "[:upper:]" "[:lower:]" <<< "$TO")"

    if xxd -p "$FILE" | tr -d "\n" | tr -d " " | grep -q "$TO"; then
        echo "\"$TO\" already applied in $(echo "$FILE" | sed "s.$WORK_DIR..")"
        return 0
    fi

    if ! xxd -p "$FILE" | tr -d "\n" | tr -d " " | grep -q "$FROM"; then
        echo "No \"$FROM\" match in $(echo "$FILE" | sed "s.$WORK_DIR..")"
        return 1
    fi

    echo "Patching \"$FROM\" to \"$TO\" in $(echo "$FILE" | sed "s.$WORK_DIR..")"
    xxd -p "$FILE" | tr -d "\n" | tr -d " " | sed "s/$FROM/$TO/" | xxd -r -p > "$FILE.tmp"
    mv "$FILE.tmp" "$FILE"
}

# REMOVE_FROM_WORK_DIR "<partition>" "<file/dir>"
# Deletes a file/directory from work dir along with its entries in fs_config/file_context.
REMOVE_FROM_WORK_DIR()
{
    local PARTITION="${1:?}"
    local FILE="${2:?}"
    local FILE_PATH
    local PATTERN
    local IS_DIR=false

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        echo "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    while [[ "${FILE:0:1}" == "/" ]]; do
        FILE="${FILE:1}"
    done

    FILE_PATH="$(_GET_WORK_DIR_PARTITION_PATH "$PARTITION")/$FILE"
    if [ ! -e "$FILE_PATH" ]; then
        echo "File not found: $FILE_PATH"
        return 0
    fi
    [ -d "$FILE_PATH" ] && IS_DIR=true

    echo "Debloating /$FILE"
    rm -rf "$FILE_PATH"

    PATTERN="${FILE//\//\\/}"
    if $IS_DIR; then
        PATTERN="/^$PATTERN/d"
    else
        PATTERN="/^$PATTERN /d"
    fi
    sed -i "$PATTERN" "$WORK_DIR/configs/fs_config-$PARTITION"

    PATTERN="${FILE//\//\\/}"
    PATTERN="${PATTERN//\./\\\.}"
    if $IS_DIR; then
        PATTERN="/^\/$PATTERN/d"
    else
        PATTERN="/^\/$PATTERN /d"
    fi
    sed -i "$PATTERN" "$WORK_DIR/configs/file_context-$PARTITION"

    if [[ "$FILE" == *".so" ]]; then
        # shellcheck disable=SC2013
        for f in $(grep -l "$(basename "$FILE")" "$WORK_DIR/system/system/etc/public.libraries"*.txt); do
            sed -i "/$(basename "$FILE")/d" "$f"
        done
    fi

    return 0
}

# SET_FLOATING_FEATURE_CONFIG "<config>" "<value>"
# Sets the supplied config to the desidered value.
# "-d" or "--delete" can be passed as value to delete the config.
SET_FLOATING_FEATURE_CONFIG()
{
    local CONFIG="${1:?}"
    local VALUE="${2:?}"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
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
    else
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
    local PARTITION="${1:?}"
    local PROP="${2:?}"
    local VALUE="${3:?}"

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        echo "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    if GET_PROP "$PARTITION" "$PROP" &> /dev/null; then
        local FILES
        FILES="$(_GET_PROP_LOCATION "$PARTITION" "$PROP")"
        # shellcheck disable=SC2116
        for f in $(echo "$FILES"); do
            if [[ "$PROP" == "-d" ]] || [[ "$PROP" == "--delete" ]]; then
                echo "Deleting \"$PROP\" prop in $f" | sed "s.$WORK_DIR..g"
                sed -i "/^$PROP/d" "$f"
            else
                echo "Replacing \"$PROP\" prop with \"$VALUE\" in $f" | sed "s.$WORK_DIR..g"

                local LINES
                LINES="$(sed -n "/^${PROP}\b/=" "$f")"
                for l in $LINES; do
                    sed -i "$l c${PROP}=${VALUE}" "$f"
                done
            fi
        done
    else
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
                if [ -f "$WORK_DIR/system_dlkm/etc/build.prop" ]; then
                    FILE="$WORK_DIR/system_dlkm/etc/build.prop"
                else
                    FILE="$WORK_DIR/system/system/system_dlkm/etc/build.prop"
                fi
                ;;
            "vendor")
                FILE="$WORK_DIR/vendor/build.prop"
                ;;
            "vendor_dlkm")
                if [ -f "$WORK_DIR/vendor_dlkm/etc/build.prop" ]; then
                    FILE="$WORK_DIR/vendor_dlkm/etc/build.prop"
                else
                    FILE="$WORK_DIR/vendor/vendor_dlkm/etc/build.prop"
                fi
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
            echo "File not found: $FILE"
            return 0
        fi

        echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
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
    local PARTITION="${1:?}"
    local PROP="${2:?}"
    local EXPECTED="${3:?}"

    if ! _IS_VALID_PARTITION_NAME "$PARTITION"; then
        echo "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    local CURRENT
    CURRENT="$(GET_PROP "$PARTITION" "$PROP")"
    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || SET_PROP "$PARTITION" "$PROP" "$EXPECTED"
}
