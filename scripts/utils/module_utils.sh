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

#[
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#131
_IS_VALID_PARTITION_NAME()
{
    [ -z "$1" ] && return 1
    echo "$1" | grep -q -w -E "system|vendor|product|system_ext|odm|vendor_dlkm|odm_dlkm|system_dlkm"
}

_GET_WORK_DIR_PARTITION_PATH()
{
    local PARTITION="$1"
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

# REMOVE_FROM_WORK_DIR "<partition>" "<file/dir>"
# Deletes a file/directory from work dir along with its entries in fs_config/file_context.
REMOVE_FROM_WORK_DIR()
{
    local PARTITION="$1"
    local FILE="$2"
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

    return 0
}
