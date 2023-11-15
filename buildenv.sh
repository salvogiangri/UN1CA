#!/bin/bash
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

# shellcheck disable=SC2012

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"

s='\<'
e='\>'

run_cmd()
{
    local CMD=$1
    local CMDS
    CMDS="$(ls --ignore "internal" "$SRC_DIR/scripts" | sed "s/.sh//")"

    if [ -z "$CMD" ] || [ "$CMD" = "-h" ]; then
        echo -e "Available cmds:\n$CMDS"
        return 1
    elif [[ ! "$CMDS" =~ $s$CMD$e ]]; then
        echo "\"$CMD\" is not valid."
        echo -e "Available cmds:\n$CMDS"
        return 1
    else
        shift
        bash "$SRC_DIR/scripts/$CMD.sh" "$@"
    fi
}
# ]

TARGETS="$(ls "$SRC_DIR/target")"

if [ -z "$1" ]; then
    echo -e "Available devices:\n$TARGETS"
    return 1
elif [[ ! "$TARGETS" =~ $s$1$e ]]; then
    echo "\"$1\" is not valid target."
    echo -e "Available devices:\n$TARGETS"
    return 1
else
    mkdir -p "$OUT_DIR"
    run_cmd build_dependencies
    bash "$SRC_DIR/scripts/internal/gen_config_file.sh" "$1"
fi

return 0
