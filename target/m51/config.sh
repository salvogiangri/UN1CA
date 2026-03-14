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

# Device configuration file for Galaxy M51 (m51)
# Download a52q firmware, then patch with m51 device tree
TARGET_NAME="Galaxy M51"
TARGET_CODENAME="m51"
TARGET_PLATFORM="sm7150"
TARGET_ASSERT_MODEL=("SM-M515F")
TARGET_FIRMWARE="SM-A525F/EUX/350281371234560"
TARGET_EXTRA_FIRMWARES=()
TARGET_PLATFORM_SDK_VERSION=34
TARGET_PRODUCT_SHIPPING_API_LEVEL=30

# SEC Product Feature
TARGET_AUDIO_SUPPORT_DUAL_SPEAKER=FALSE
TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME="dvfs_policy_sm7150_xx"
TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_m51_sm7150"
TARGET_FINGERPRINT_CONFIG_SENSOR="google_touch_side,settings=3,navi=1"
TARGET_COMMON_CONFIG_MDNIE_MODE="62481"