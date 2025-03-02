#
# Copyright (C) 2024 Salvo Giangreco
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

# Debloat list for Galaxy S21 FE 5G (Qualcomm) (r9q2)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
PRODUCT_DEBLOAT+="
overlay/SoftapOverlay6GHz
overlay/SoftapOverlayDualAp
overlay/SoftapOverlayOWE
"

# mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8550
"

# Camera SDK
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.petservice.xml
system/etc/default-permissions/default-permissions-com.samsung.videoscan.xml
system/etc/permissions/privapp-permissions-com.samsung.petservice.xml
system/etc/permissions/privapp-permissions-com.samsung.videoscan.xml
system/priv-app/PetService
system/priv-app/VideoScan
"

# system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
app/QCC
bin/qccsyshal@1.2-service
etc/init/vendor.qti.hardware.qccsyshal@1.2-service.rc
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
lib/libqcc.so
lib/libqcc_file_agent_sys.so
lib/libqccdme.so
lib/libqccfileservice.so
lib/vendor.qti.hardware.qccsyshal@1.0.so
lib/vendor.qti.hardware.qccsyshal@1.1.so
lib/vendor.qti.hardware.qccsyshal@1.2.so
lib/vendor.qti.hardware.qccvndhal@1.0.so
lib/vendor.qti.qccvndhal_aidl-V1-ndk.so
lib64/libqcc.so
lib64/libqcc_file_agent_sys.so
lib64/libqccdme.so
lib64/libqccfileservice.so
lib64/vendor.qti.hardware.qccsyshal@1.0.so
lib64/vendor.qti.hardware.qccsyshal@1.1.so
lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so
lib64/vendor.qti.hardware.qccsyshal@1.2.so
lib64/vendor.qti.hardware.qccvndhal@1.0.so
lib64/vendor.qti.qccvndhal_aidl-V1-ndk.so
priv-app/com.qualcomm.location
"
