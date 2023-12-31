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

# Debloat list for Galaxy A54 5G (a54x)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppQC
system/app/WifiRROverlayAppWifiLock
"
PRODUCT_DEBLOAT+="
overlay/SoftapOverlay6GHz
overlay/SoftapOverlayOWE
overlay/SoftapOverlayQC
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/DevGPUDriver-EX2200
system/priv-app/GameDriver-EX2200
"

# Camera SDK
SYSTEM_DEBLOAT+="
system/etc/permissions/cameraservice.xml
system/framework/scamera_sep.jar
system/priv-app/SCameraSDKService
"

# system_ext clean-up
SYSTEM_DEBLOAT+="
system/etc/permissions/org.carconnectivity.android.digitalkey.rangingintent.xml
system/etc/permissions/org.carconnectivity.android.digitalkey.secureelement.xml
"
SYSTEM_EXT_DEBLOAT+="
framework/org.carconnectivity.android.digitalkey.rangingintent.jar
framework/org.carconnectivity.android.digitalkey.secureelement.jar
framework/oat/arm/org.carconnectivity.android.digitalkey.rangingintent.odex
framework/oat/arm/org.carconnectivity.android.digitalkey.rangingintent.vdex
framework/oat/arm/org.carconnectivity.android.digitalkey.secureelement.odex
framework/oat/arm/org.carconnectivity.android.digitalkey.secureelement.vdex
framework/oat/arm64/org.carconnectivity.android.digitalkey.rangingintent.odex
framework/oat/arm64/org.carconnectivity.android.digitalkey.rangingintent.vdex
framework/oat/arm64/org.carconnectivity.android.digitalkey.secureelement.odex
framework/oat/arm64/org.carconnectivity.android.digitalkey.secureelement.vdex
"
