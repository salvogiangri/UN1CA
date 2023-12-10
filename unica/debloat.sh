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
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Samsung Defex policy
SYSTEM_DEBLOAT+="
dpolicy_system
"
VENDOR_DEBLOAT+="
etc/dpolicy
"

# WSM
SYSTEM_DEBLOAT+="
system/etc/public.libraries-wsm.samsung.txt
system/lib/libhal.wsm.samsung.so
system/lib/vendor.samsung.hardware.security.wsm.service-V1-ndk.so
system/lib64/libhal.wsm.samsung.so
system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so
"

# .odex files
SYSTEM_DEBLOAT+="
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
"

# Recovery restoration script
VENDOR_DEBLOAT+="
recovery-from-boot.p
bin/install-recovery.sh
etc/init/vendor_flash_recovery.rc
"

# Apps debloat
PRODUCT_DEBLOAT+="
app/Chrome
app/DuoStub
app/Gmail2
app/Maps
app/YouTube
priv-app/Messages
priv-app/SearchSelector
priv-app/Velvet
"
SYSTEM_DEBLOAT+="
system/app/FBAppManager_NS
system/app/PlayAutoInstallConfig
system/app/SamsungPassAutofill_v1
system/etc/init/samsung_pass_authenticator_service.rc
system/etc/permissions/privapp-permissions-com.microsoft.skydrive.xml
system/etc/permissions/privapp-permissions-com.samsung.android.app.kfa.xml
system/etc/permissions/privapp-permissions-com.samsung.android.authfw.xml
system/etc/permissions/privapp-permissions-com.samsung.android.carkey.xml
system/etc/permissions/privapp-permissions-com.samsung.android.dkey.xml
system/etc/permissions/privapp-permissions-com.samsung.android.samsungpass.xml
system/etc/permissions/privapp-permissions-com.samsung.android.spayfw.xml
system/etc/permissions/privapp-permissions-com.wssyncmldm.xml
system/etc/permissions/privapp-permissions-meta.xml
system/etc/sysconfig/digitalkey.xml
system/etc/sysconfig/meta-hiddenapi-package-allowlist.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.dkey.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.spayfw.xml
system/etc/sysconfig/samsungauthframework.xml
system/etc/sysconfig/samsungpassapp.xml
system/hidden/SmartTutor
system/preload/Facebook_stub_preload
system/priv-app/AuthFramework
system/priv-app/DigitalKey
system/priv-app/FBInstaller_NS
system/priv-app/FBServices
system/priv-app/FotaAgent
system/priv-app/KnoxAIFrameworkApp
system/priv-app/OneDrive_Samsung_v3
system/priv-app/PaymentFramework
system/priv-app/SamsungCarKeyFw
system/priv-app/SamsungPass
"

# eSIM
if $SOURCE_IS_ESIM_SUPPORTED; then
    if ! $TARGET_IS_ESIM_SUPPORTED; then
        SYSTEM_DEBLOAT+="
        system/etc/permissions/privapp-permissions-com.samsung.euicc.xml
        system/etc/sysconfig/preinstalled-packages-com.samsung.euicc.xml
        system/priv-app/EuiccService
        "
    fi
fi
