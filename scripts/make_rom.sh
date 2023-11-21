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
# ]

bash "$SRC_DIR/scripts/download_fw.sh"
bash "$SRC_DIR/scripts/extract_fw.sh"

echo -e "- Creating work dir..."
bash "$SRC_DIR/scripts/internal/create_work_dir.sh"

echo -e "\n- Applying debloat list..."
bash "$SRC_DIR/scripts/internal/apply_debloat.sh"

echo -e "\n- Applying ROM patches..."
bash "$SRC_DIR/scripts/internal/apply_patches.sh"

exit 0
