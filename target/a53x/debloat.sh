# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy A53 5G (a53x)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppLls
system/app/WifiRROverlayAppWifiLock
"
PRODUCT_DEBLOAT+="
overlay/SoftapOverlayQC
"

# mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# DevGPUDriver
SYSTEM_DEBLOAT+="
system/priv-app/DevGPUDriver-EX2200
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-EX2200
"

# vendor clean-up
VENDOR_DEBLOAT+="
etc/somxreg.conf
etc/init/fingerprint_common.rc
etc/init/vendor.samsung.rilchip.slsi.rc
"
