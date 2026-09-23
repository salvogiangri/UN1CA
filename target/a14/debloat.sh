# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy A14 4G (a14)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Apps debloat
PRODUCT_DEBLOAT+="
priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55
priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55
"

# system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.android.hotwordenrollment.common.util.xml
framework/com.android.hotwordenrollment.common.util.jar
"
