# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy A71 (a71)
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

# HDCP
SYSTEM_DEBLOAT+="
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8450
"

# Apps debloat
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.earphonetypec.xml
system/priv-app/EarphoneTypeC
"
PRODUCT_DEBLOAT+="
priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON
priv-app/HotwordEnrollmentXGoogleEx4HEXAGON
"

# system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.android.hotwordenrollment.common.util.xml
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.android.hotwordenrollment.common.util.jar
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"
