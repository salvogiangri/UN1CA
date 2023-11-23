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

# UN1CA debloat list
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

ODM_DEBLOAT="
"

PRODUCT_DEBLOAT="
"

SYSTEM_DEBLOAT="
dpolicy_system
system/etc/permissions/privapp-permissions-com.microsoft.skydrive.xml
system/etc/permissions/privapp-permissions-com.wssyncmldm.xml
system/framework/arm
system/framework/arm64
system/framework/oat
system/framework/boot-apache-xml.vdex
system/framework/boot-bouncycastle.vdex
system/framework/boot-core-icu4j.vdex
system/framework/boot-core-libart.vdex
system/framework/boot-esecomm.vdex
system/framework/boot-ext.vdex
system/framework/boot-framework-adservices.vdex
system/framework/boot-framework-graphics.vdex
system/framework/boot-framework.vdex
system/framework/boot-ims-common.vdex
system/framework/boot-knoxsdk.vdex
system/framework/boot-okhttp.vdex
system/framework/boot-QPerformance.vdex
system/framework/boot-tcmiface.vdex
system/framework/boot-telephony-common.vdex
system/framework/boot-telephony-ext.vdex
system/framework/boot-UxPerformance.vdex
system/framework/boot.vdex
system/framework/boot-voip-common.vdex
system/priv-app/FotaAgent
system/priv-app/OneDrive_Samsung_v3
"

SYSTEM_EXT_DEBLOAT="
"

VENDOR_DEBLOAT="
recovery-from-boot.p
tima_measurement_info
bin/install-recovery.sh
etc/dpolicy
etc/init/vendor_flash_recovery.rc
"
