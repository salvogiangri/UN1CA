# shellcheck shell=bash
DECODE_APK "system" "system/priv-app/Telecom/Telecom.apk"
LOG "- Adding 2018 call connect/disconnect sounds"
cp -a "$MODPATH/Telecom.apk/"* "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk"
