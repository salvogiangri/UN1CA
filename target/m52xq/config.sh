#
# Copyright (C) 2023 Salvo Giangreco
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

# Device configuration file for Galaxy M52 5G (m52xq)
TARGET_NAME="Galaxy M52 5G"
TARGET_CODENAME="m52xq"
TARGET_FIRMWARE="SM-M526BR/BTU/355568761234563"
TARGET_EXTRA_FIRMWARES=()
TARGET_API_LEVEL=33
TARGET_PRODUCT_FIRST_API_LEVEL=30
TARGET_VNDK_VERSION=30
TARGET_SINGLE_SYSTEM_IMAGE="qssi"
TARGET_OS_FILE_SYSTEM="ext4"
TARGET_HAS_COMMON_TARGET=true
TARGET_COMMON_NAME="sm7325-common"
TARGET_SUPER_PARTITION_SIZE=10328473600
TARGET_SUPER_GROUP_SIZE=10324279296
TARGET_HAS_SYSTEM_EXT=false

# SEC Product Feature
TARGET_AUDIO_SUPPORT_ACH_RINGTONE=false
TARGET_AUDIO_SUPPORT_DUAL_SPEAKER=false
TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION=false
TARGET_AUTO_BRIGHTNESS_TYPE="3"
TARGET_DVFS_CONFIG_NAME="dvfs_policy_sm7325_xx"
TARGET_FP_SENSOR_CONFIG="google_touch_side,settings=3,navi=1"
TARGET_HAS_HW_MDNIE=true
TARGET_HAS_MASS_CAMERA_APP=true
TARGET_HAS_QHD_DISPLAY=false
#TARGET_HFR_MODE="1"
TARGET_HFR_MODE="2"
TARGET_HFR_SUPPORTED_REFRESH_RATE="60,120"
TARGET_HFR_DEFAULT_REFRESH_RATE="120"
TARGET_IS_ESIM_SUPPORTED=false
TARGET_MDNIE_SUPPORTED_MODES="65301"
TARGET_MDNIE_WEAKNESS_SOLUTION_FUNCTION="3"
TARGET_MULTI_MIC_MANAGER_VERSION="07010"
TARGET_SSRM_CONFIG_NAME="siop_m52xq_sm7325"
TARGET_SUPPORT_CUTOUT_PROTECTION=false
