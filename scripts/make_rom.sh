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

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"

START=$SECONDS

source "$OUT_DIR/config.sh"
# ]

if [[ ! -f "$WORK_DIR/.completed" ]]; then
    bash -e "$SRC_DIR/scripts/download_fw.sh"
    bash -e "$SRC_DIR/scripts/extract_fw.sh"

    echo -e "- Creating work dir..."
    bash -e "$SRC_DIR/scripts/internal/create_work_dir.sh"

    echo -e "\n- Applying debloat list..."
    bash -e "$SRC_DIR/scripts/internal/apply_debloat.sh"

    echo -e "\n- Applying ROM patches..."
    find "$SRC_DIR/unica/patches" -maxdepth 1 -executable -type f -exec bash -e {} \;
    [[ -d "$SRC_DIR/target/$TARGET_CODENAME/patches" ]] \
        && find "$SRC_DIR/target/$TARGET_CODENAME/patches" -maxdepth 1 -executable -type f -exec bash -e {} \;

    echo ""
    touch "$WORK_DIR/.completed"
fi

echo "- Building ROM zip..."
bash -e "$SRC_DIR/scripts/internal/build_flashable_zip.sh"

ESTIMATED=$((SECONDS-START))
echo -e "\nBuild completed in $((ESTIMATED / 3600))hrs $(((ESTIMATED / 60) % 60))min $((ESTIMATED % 60))sec."

exit 0
