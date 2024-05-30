if [ ! -d "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk" ]; then
    bash "$SRC_DIR/scripts/apktool.sh" d "/system/priv-app/Telecom/Telecom.apk"
fi
cp -a --preserve=all "$SRC_DIR/unica/mods/callsounds/Telecom.apk/"* "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk"
