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

# Platform configuration file for for Qualcomm Snapdragon 778G devices (sm7325)
TARGET_BOARD_API_LEVEL=30

# Partitions
TARGET_BOOT_PARTITION_SIZE=100663296
TARGET_DTBO_PARTITION_SIZE=25165824
TARGET_VENDOR_BOOT_PARTITION_SIZE=100663296

# Dynamic partitions
TARGET_SUPER_GROUP_NAME="qti_dynamic_partitions"

# OS
TARGET_OS_SINGLE_SYSTEM_IMAGE="qssi"
TARGET_OS_BUILD_SYSTEM_EXT_PARTITION=false

# SEC Product Feature
TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION="0"
TARGET_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD="100"
TARGET_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD="0"
TARGET_WLAN_CONFIG_DYNAMIC_SWITCH="0"
TARGET_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD="0"
TARGET_WLAN_SUPPORT_80211AX=true
TARGET_WLAN_SUPPORT_80211AX_6GHZ=true
TARGET_WLAN_SUPPORT_APE_SERVICE=false
TARGET_WLAN_SUPPORT_LOWLATENCY=false
TARGET_WLAN_SUPPORT_MBO=true
TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY=false
TARGET_WLAN_SUPPORT_MOBILEAP_6G=false
TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE=false
TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC=false
TARGET_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY=true
TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE=true
TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS=true
TARGET_WLAN_SUPPORT_TWT_CONTROL=false
TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR=false
