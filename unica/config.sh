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

# UN1CA configuration file
ROM_VERSION="beta-$(git rev-parse --short HEAD)"

# Source ROM firmware
case "$TARGET_SINGLE_SYSTEM_IMAGE" in
    # Qualcomm
    "qssi")
        # Galaxy S23 (One UI 6.0)
        SOURCE_FIRMWARE="SM-S911B/INS"
        SOURCE_EXTRA_FIRMWARES=()
        SOURCE_API_LEVEL=34
        SOURCE_VNDK_VERSION=33
        SOURCE_HAS_SYSTEM_EXT=true
        # SEC Product Feature
        SOURCE_HAS_KNOX_DUALDAR=true
        SOURCE_HAS_KNOX_SDP=false
        SOURCE_HAS_KEYMINT=true
        SOURCE_HAS_MASS_CAMERA_APP=false
        SOURCE_HAS_OPTICAL_FP_SENSOR=false
        SOURCE_IS_ESIM_SUPPORTED=true
        ;;
    *)
        echo "\"$TARGET_SINGLE_SYSTEM_IMAGE\" is not a valid system image."
        return 1
        ;;
esac

return 0
