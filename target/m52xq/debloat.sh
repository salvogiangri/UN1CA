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

# Debloat list for Galaxy M52 5G (m52xq)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
PRODUCT_DEBLOAT+="
overlay/SoftapOverlay6GHz
overlay/SoftapOverlayOWE
"

# fabric_crypto
SYSTEM_DEBLOAT+="
system/bin/fabric_crypto
system/etc/init/fabric_crypto.rc
system/etc/permissions/FabricCryptoLib.xml
system/etc/vintf/manifest/fabric_crypto_manifest.xml
system/framework/FabricCryptoLib.jar
system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so
system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so
"

# HDCP
SYSTEM_DEBLOAT+="
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8550
"

# QCC
SYSTEM_EXT_DEBLOAT+="
app/QCC
bin/qccsyshal@1.2-service
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
"

# Qualcomm IPA firmware blobs
VENDOR_DEBLOAT+="
firmware/ipa_fws.b00
firmware/ipa_fws.b01
firmware/ipa_fws.b02
firmware/ipa_fws.b03
firmware/ipa_fws.b04
firmware/ipa_fws.elf
firmware/ipa_fws.mdt
firmware/yupik_ipa_fws.b00
firmware/yupik_ipa_fws.b01
firmware/yupik_ipa_fws.b02
firmware/yupik_ipa_fws.b03
firmware/yupik_ipa_fws.b04
firmware/yupik_ipa_fws.elf
firmware/yupik_ipa_fws.mdt
"
