GET_PROP()
{
    local PROP="$1"
    local FILE="$2"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    grep "^$PROP=" "$FILE" | cut -d "=" -f2-
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/bin/rezetprop u:object_r:system_file:s0"
        echo "/system/media/audio/ui/PowerOn\.ogg u:object_r:system_file:s0"
        echo "/system/media/audio/ui/PowerOff\.ogg u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/bin/rezetprop 0 2000 755 capabilities=0x0"
        echo "system/media/audio/ui/PowerOn.ogg 0 0 644 capabilities=0x0"
        echo "system/media/audio/ui/PowerOff.ogg 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/privapp-permissions-com.samsung.android.kgclient.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/public.libraries-wsm.samsung.txt"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libhal.wsm.samsung.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libhal.wsm.samsung.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/KnoxGuard"

echo -e "\n" >> "$WORK_DIR/system/system/etc/init/ssu_dm1qxxx.rc"
echo    "on property:service.bootanim.exit=1" >> "$WORK_DIR/system/system/etc/init/ssu_dm1qxxx.rc"
echo    "    exec u:r:magisk:s0 root root -- /system/bin/rezetprop -n ro.boot.verifiedbootstate green" >> "$WORK_DIR/system/system/etc/init/ssu_$CODENAME.rc"
echo -n "    exec u:r:su:s0 root root -- /system/bin/rezetprop -n ro.boot.verifiedbootstate green" >> "$WORK_DIR/system/system/etc/init/ssu_$CODENAME.rc"
if [[ "$(GET_PROP "ro.product.first_api_level" "$WORK_DIR/vendor/build.prop")" -ge "33" ]]; then
    echo -e "\n    exec u:r:magisk:s0 root root -- /system/bin/rezetprop -n ro.product.first_api_level 32" >> "$WORK_DIR/system/system/etc/init/ssu_$CODENAME.rc"
    echo -n "    exec u:r:su:s0 root root -- /system/bin/rezetprop -n ro.product.first_api_level 32" >> "$WORK_DIR/system/system/etc/init/ssu_$CODENAME.rc"
fi

echo "ro.unica.version=$ROM_VERSION" >> "$WORK_DIR/system/system/build.prop"
echo "ro.unica.codename=$ROM_CODENAME" >> "$WORK_DIR/system/system/build.prop"

if [ ! -d "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" ]; then
    bash "$SRC_DIR/scripts/apktool.sh" d "/system/priv-app/SecSettings/SecSettings.apk"
fi
cp -a --preserve=all "$SRC_DIR/unica/mods/mods/SecSettings.apk/"* "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk"

if [ ! -d "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk" ]; then
    bash "$SRC_DIR/scripts/apktool.sh" d "/system/priv-app/Telecom/Telecom.apk"
fi
cp -a --preserve=all "$SRC_DIR/unica/mods/mods/Telecom.apk/"* "$APKTOOL_DIR/system/priv-app/Telecom/Telecom.apk"
