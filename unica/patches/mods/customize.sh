if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/media/audio/ui/PowerOn\.ogg u:object_r:system_file:s0"
        echo "/system/media/audio/ui/PowerOff\.ogg u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/media/audio/ui/PowerOn.ogg 0 0 644 capabilities=0x0"
        echo "system/media/audio/ui/PowerOff.ogg 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi

echo "ro.unica.version=$ROM_VERSION" >> "$WORK_DIR/system/system/build.prop"

if [ ! -d "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" ]; then
    bash "$SRC_DIR/scripts/apktool.sh" d "/system/priv-app/SecSettings/SecSettings.apk"
fi
cp -a --preserve=all "$SRC_DIR/unica/patches/mods/SecSettings.apk/"* "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk"

if [ ! -d "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk" ]; then
    bash "$SRC_DIR/scripts/apktool.sh" d "/system/priv-app/Telecom/Telecom.apk"
fi
cp -a --preserve=all "$SRC_DIR/unica/patches/mods/Telecom.apk/"* "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk"
