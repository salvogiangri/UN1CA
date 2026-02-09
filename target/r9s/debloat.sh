# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy S21 FE 5G (Exynos) (r9s)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppH2E
"

# mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# Apps debloat
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.sec.android.cover.ledcover.xml
system/priv-app/LedCoverService
"
