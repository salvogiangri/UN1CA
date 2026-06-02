#
# Copyright (C) 2023 Salvo Giangreco
# ...
#

# Debloat list for Galaxy Tab S7 (WIFI) (gts7lwifi)

# Overlays
SYSTEM_DEBLOAT+="
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

# system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"