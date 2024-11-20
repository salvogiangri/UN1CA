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

# shellcheck disable=SC1007,SC1091,SC2046,SC2164

# [
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/envsetup.sh#18
_GET_SRC_DIR()
{
    local TOPFILE="unica/config.sh"
    if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/$TOPFILE" ]; then
        # The following circumlocution ensures we remove symlinks from SRC_DIR.
        (cd "$SRC_DIR"; PWD= /bin/pwd)
    else
        if [ -f "$TOPFILE" ]; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE="$PWD"
            local T=
            while [ \( ! \( -f "$TOPFILE" \) \) ] && [ \( "$PWD" != "/" \) ]; do
                \cd ..
                T="$(PWD= /bin/pwd -P)"
            done
            \cd "$HERE"
            if [ -f "$T/$TOPFILE" ]; then
                echo "$T"
            fi
        fi
    fi
}

run_cmd()
{
    local CMD=$1

    local CMDS
    CMDS="$(find "$SRC_DIR/scripts" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' -o -type l -printf '%f\n' | sort | sed "s/.sh//g")"

    if [ -z "$CMD" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ]; then
        echo -e "Available cmds:\n$CMDS"
        return 1
    elif ! echo "$CMDS" | grep -w -- "$CMD" &> /dev/null; then
        echo    "\"$CMD\" is not valid." >&2
        echo -e "Available cmds:\n$CMDS" >&2
        return 1
    else
        shift
        "$SRC_DIR/scripts/$CMD.sh" "$@"
        return $?
    fi
}

alias unica=run_cmd

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/envsetup.sh#806
croot()
{
    if [ -d "$SRC_DIR" ]; then
        if [ "$1" ]; then
            cd "$SRC_DIR/$1"
        else
            cd "$SRC_DIR"
        fi
    else
        echo "Couldn't locate the top of the tree. Try setting SRC_DIR."
        return 1
    fi
}
# ]

SRC_DIR="$(_GET_SRC_DIR)"
if [ ! "$SRC_DIR" ]; then
    echo "Couldn't locate the top of the tree. Always source buildenv.sh from the root of the tree." >&2
    return 1
fi

unset -f _GET_SRC_DIR

export SRC_DIR
export OUT_DIR="$SRC_DIR/out"
export TMP_DIR="$OUT_DIR/tmp"
export ODIN_DIR="$OUT_DIR/odin"
export FW_DIR="$OUT_DIR/fw"
export APKTOOL_DIR="$OUT_DIR/apktool"
export WORK_DIR="$OUT_DIR/work_dir"
export TOOLS_DIR="$OUT_DIR/tools/bin"
export PATH="$TOOLS_DIR:$PATH"

TARGETS=()
while IFS='' read -r t; do TARGETS+=("$t"); done < <(find "$SRC_DIR/target" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

if [ "$#" -gt 1 ]; then
    echo "Usage: source buildenv.sh <target>" >&2
    echo "Available devices:" >&2
    for t in "${TARGETS[@]}"
    do
        echo "$t" >&2
    done
    return 1
elif [ "$#" -ne 1 ]; then
    echo "No target specified. Please choose from the available devices below:"

    select SELECTED_TARGET in "${TARGETS[@]}"; do
        if [ -n "$SELECTED_TARGET" ]; then
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
else
    SELECTED_TARGET="$1"
fi

if ! echo "${TARGETS[@]}" | grep -w -- "$SELECTED_TARGET" &> /dev/null; then
    echo "\"$SELECTED_TARGET\" is not a valid device." >&2
    echo "Available devices:" >&2
    for t in "${TARGETS[@]}"
    do
        echo "$t" >&2
    done
    return 1
fi

mkdir -p "$OUT_DIR"
run_cmd build_dependencies || return 1
[ -f "$OUT_DIR/config.sh" ] && unset $(sed "/Automatically/d" "$OUT_DIR/config.sh" | cut -d= -f1)
"$SRC_DIR/scripts/internal/gen_config_file.sh" "$SELECTED_TARGET" || return 1
set -o allexport; source "$OUT_DIR/config.sh"; set +o allexport

unset TARGETS SELECTED_TARGET

echo "=============================="
sed "/Automatically/d" "$OUT_DIR/config.sh"
echo "=============================="

return 0
