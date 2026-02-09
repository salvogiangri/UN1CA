# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

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

# Samsung PROCA certificate DB
SYSTEM_DEBLOAT+="
system/etc/proca.db
"

# Samsung SIM Unlock
SYSTEM_DEBLOAT+="
system/bin/ssud
system/etc/init/ssu_$(GET_PROP "system" "ro.product.system.name").rc
system/etc/init/ssu.rc
system/etc/permissions/privapp-permissions-com.samsung.ssu.xml
system/etc/sysconfig/samsungsimunlock.xml
system/lib64/android.security.securekeygeneration-ndk.so
system/lib64/libssu_keystore2.so
system/priv-app/SsuService
"

# Recovery restoration script
VENDOR_DEBLOAT+="
recovery-from-boot.p
bin/install-recovery.sh
etc/init/vendor_flash_recovery.rc
"

# PDP apps
SYSTEM_DEBLOAT+="
system/preload
"

truncate -s 0 "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"

# eSIM
[[ "$TARGET_COMMON_SUPPORT_EMBEDDED_SIM" == "false" ]] && SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.esimkeystring.xml
system/etc/permissions/privapp-permissions-com.samsung.euicc.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.app.esimkeystring.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.euicc.xml
system/priv-app/EsimKeyString
system/priv-app/EuiccService
"

# SmartFPSAdjuster
[ "$TARGET_LCD_CONFIG_HFR_MODE" -lt "1" ] && SYSTEM_DEBLOAT+="
system/priv-app/IntelligentDynamicFpsService
"

# Application recommendations
SYSTEM_DEBLOAT+="
system/app/MAPSAgent
"

# AppUpdateCenter
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.updatecenter.xml
system/priv-app/AppUpdateCenter
"

# BCService
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.sec.bcservice.xml
system/priv-app/BCService
"

# Gaming Hub
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.game.gamehome.xml
system/priv-app/GameHome
"

ADD_TO_WORK_DIR "pa2qxxx" "system" \
    "system/etc/permissions/signature-permissions-com.samsung.android.game.gamehome.xml" \
    0 0 644 "u:object_r:system_file:s0"

# Gemini shortcut
PRODUCT_DEBLOAT+="
app/BardShell
"

# Gmail
PRODUCT_DEBLOAT+="
app/Gmail2
"

# Google Assistant shortcut
PRODUCT_DEBLOAT+="
app/AssistantShell
"

# Google Chrome
PRODUCT_DEBLOAT+="
app/Chrome
"

# Google Duo
PRODUCT_DEBLOAT+="
app/DuoStub
"

# Google Maps
PRODUCT_DEBLOAT+="
app/Maps
"

# Google PAI (Play Autoinstall)
SYSTEM_DEBLOAT+="
system/app/PlayAutoInstallConfig
"

# HwModuleTest
SYSTEM_DEBLOAT+="
system/app/Cameralyzer
system/app/FactoryAirCommandManager
system/app/FactoryCameraFB
system/app/HMT
system/app/WlanTest
system/etc/default-permissions/default-permissions-com.sec.factory.cameralyzer.xml
system/etc/permissions/privapp-permissions-com.samsung.android.providers.factory.xml
system/etc/permissions/privapp-permissions-com.sec.facatfunction.xml
system/priv-app/FacAtFunction
system/priv-app/FactoryTestProvider
"

# Language packs
SYSTEM_DEBLOAT+="$(find "$WORK_DIR/system" -type d -name "*TTSVoice*" | sed "s|$WORK_DIR/system/||g")"

# LED Cover Service
[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_NFC_LED_COVER_LEVEL")" -lt "30" ] && SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.sec.android.cover.ledcover.xml
system/priv-app/LedCoverService
"

# Link to Windows
# Replace full apk with stub apk to save space
SYSTEM_DEBLOAT+="
system/priv-app/YourPhone_P1_5
"

# Live Transcribe
SYSTEM_DEBLOAT+="
system/app/LiveTranscribe
system/etc/sysconfig/feature-a11y-preload.xml
"

# Meta
SYSTEM_DEBLOAT+="
system/app/FBAppManager_NS
system/etc/default-permissions/default-permissions-meta.xml
system/etc/permissions/privapp-permissions-meta.xml
system/etc/sysconfig/meta-hiddenapi-package-allowlist.xml
system/priv-app/FBInstaller_NS
system/priv-app/FBServices
"

# Microsoft OneDrive
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.microsoft.skydrive.xml
system/priv-app/OneDrive_Samsung_v3
"

# My Galaxy
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.mygalaxy.service.xml
system/etc/sysconfig/preinstalled-packages-com.mygalaxy.service.xml
system/priv-app/MyGalaxyService
"

# Samsung Analytics
SYSTEM_DEBLOAT+="
system/app/DsmsAPK
system/etc/permissions/privapp-permissions-com.samsung.android.dqagent.xml
system/etc/permissions/privapp-permissions-com.sec.android.diagmonagent.xml
system/etc/permissions/privapp-permissions-com.sec.android.soagent.xml
system/priv-app/DeviceQualityAgent36
system/priv-app/DiagMonAgent95
system/priv-app/SOAgent76
"

SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CONTEXTSERVICE_ENABLE_SURVEY_MODE" --delete

# Samsung AR Emoji
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.sec.android.mimage.avatarstickers.xml
system/etc/permissions/privapp-permissions-com.samsung.android.aremojieditor.xml
system/etc/permissions/privapp-permissions-com.sec.android.mimage.avatarstickers.xml
system/etc/permissions/signature-permissions-com.sec.android.mimage.avatarstickers.xml
system/priv-app/AREmojiEditor
system/priv-app/AvatarEmojiSticker
"

# Samsung Calendar
SYSTEM_DEBLOAT+="
system/app/SamsungCalendar
"

# Samsung Clock
SYSTEM_DEBLOAT+="
system/app/ClockPackage
"

# Samsung Free
SYSTEM_DEBLOAT+="
system/app/MinusOnePage
"

# Samsung Language Core
SYSTEM_DEBLOAT+="
system/etc/permissions/signature-permissions-com.samsung.android.offline.languagemodel.xml
system/priv-app/OfflineLanguageModel_stub
"

# Samsung Messages
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.android.messaging.xml
system/etc/permissions/privapp-permissions-com.samsung.android.messaging.xml
system/priv-app/SamsungMessages
"

# Samsung Pass
SYSTEM_DEBLOAT+="
system/app/SamsungPassAutofill_v1
system/etc/init/samsung_pass_authenticator_service.rc
system/etc/permissions/authfw.xml
system/etc/permissions/privapp-permissions-com.samsung.android.authfw.xml
system/etc/permissions/privapp-permissions-com.samsung.android.samsungpass.xml
system/etc/permissions/signature-permissions-com.samsung.android.samsungpass.xml
system/etc/permissions/signature-permissions-com.samsung.android.samsungpassautofill.xml
system/etc/sysconfig/samsungauthframework.xml
system/etc/sysconfig/samsungpassapp.xml
system/priv-app/AuthFramework
system/priv-app/SamsungPass
"

# Samsung Reminder
SYSTEM_DEBLOAT+="
system/app/SmartReminder
"

# Samsung Visit In
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.ipsgeofence.xml
system/priv-app/IpsGeofence
"

# Samsung Wallet
SYSTEM_DEBLOAT+="
system/etc/init/digitalkey_init_ble_tss2.rc
system/etc/permissions/org.carconnectivity.android.digitalkey.rangingintent.xml
system/etc/permissions/org.carconnectivity.android.digitalkey.secureelement.xml
system/etc/permissions/privapp-permissions-com.samsung.android.carkey.xml
system/etc/permissions/privapp-permissions-com.samsung.android.dkey.xml
system/etc/permissions/privapp-permissions-com.samsung.android.spayfw.xml
system/etc/permissions/signature-permissions-com.samsung.android.spay.xml
system/etc/permissions/signature-permissions-com.samsung.android.spayfw.xml
system/etc/sysconfig/digitalkey.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.dkey.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.spayfw.xml
system/priv-app/DigitalKey
system/priv-app/PaymentFramework
system/priv-app/SamsungCarKeyFw
"
SYSTEM_EXT_DEBLOAT+="
framework/org.carconnectivity.android.digitalkey.rangingintent.jar
framework/org.carconnectivity.android.digitalkey.secureelement.jar
"

# Search engine selector
PRODUCT_DEBLOAT+="
overlay/GmsConfigOverlaySearchSelector.apk
priv-app/SearchSelector
"

# SettingsHelper
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.settingshelper.xml
system/etc/sysconfig/settingshelper.xml
system/priv-app/SHClient
"

# Smart Touch Call
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.android.visualars.xml
system/etc/permissions/privapp-permissions-com.samsung.android.visualars.xml
system/priv-app/SmartTouchCall
"

# Smart Tutor
SYSTEM_DEBLOAT+="
system/hidden/SmartTutor
"

SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_SMARTTUTOR_PACKAGES_PATH" --delete

# Software update
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.wssyncmldm.xml
system/priv-app/FotaAgent
"

# SVC Agent
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.svcagent.xml
system/priv-app/SVCAgent
"

# SVoiceIME
SYSTEM_DEBLOAT+="
system/priv-app/SVoiceIME
"

# Voice Access
SYSTEM_DEBLOAT+="
system/app/VoiceAccess
system/etc/sysconfig/feature-a11y-preload-voacc.xml
"

# YouTube
PRODUCT_DEBLOAT+="
app/YouTube
"
