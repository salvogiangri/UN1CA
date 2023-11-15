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

# Current API level
API_LEVEL=34

# Base ROM firmware
# Qualcomm: Galaxy S23
if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    SOURCE_FIRMWARE="SM-S911B/BTE"
    SOURCE_HAS_SYSTEM_EXT=true
else
    echo "\"$TARGET_SINGLE_SYSTEM_IMAGE\" is not a valid system image."
    exit 1
fi
