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

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"
# ]

source "$SRC_DIR/config.sh"
[ "${#FIRMWARES[@]}" -ge "1" ] || exit 1

PDR="$(pwd)"
mkdir -p "$OUT_DIR/fw"
cd "$OUT_DIR/fw"
for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)
    echo "- Downloading $MODEL firmware with $REGION CSC..."
    samfirm -m $MODEL -r $REGION 2>&1 > /dev/null
done
cd "$PDR"
