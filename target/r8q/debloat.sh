# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy S20 FE (Snapdragon) (r8q)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppH2E
system/app/WifiRROverlayAppLls
"

# mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8450
"

# system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"
