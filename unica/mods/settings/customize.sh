SET_PROP "system" "ro.unica.version" "$ROM_VERSION"
SET_PROP "system" "ro.unica.codename" "$ROM_CODENAME"

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
cp -a --preserve=all "$SRC_DIR/unica/mods/settings/SecSettings.apk/"* "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk"
