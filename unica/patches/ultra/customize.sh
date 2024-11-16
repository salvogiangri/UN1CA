SKIPUNZIP=1

# [
DECOMPILE()
{
    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        bash "$SRC_DIR/scripts/apktool.sh" d "$1"
    fi
}

APPLY_PATCH()
{
    local PATCH
    local COMMIT_NAME
    local OUT

    DECOMPILE "$1"

    cd "$APKTOOL_DIR/$1"
    PATCH="$SRC_DIR/unica/patches/ultra/$2"
    COMMIT_NAME="$(grep "^Subject:" "$PATCH" | sed 's/.*PATCH] //')"
    echo "Applying \"$COMMIT_NAME\" to /$1"
    OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
        || echo "$OUT" | grep -q "Skipping patch" || false
    patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
    cd - &> /dev/null
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ -d "$FW_DIR/${MODEL}_${REGION}/system/system/media/audio/pensounds" ]; then

    cp -a --preserve=all "$SRC_DIR/unica/patches/ultra/system/"* "$WORK_DIR/system/system"

    if ! grep -q "AirReadingGlass" "$WORK_DIR/configs/file_context-system"; then
        {
            echo "/system/app/AirGlance u:object_r:system_file:s0"
            echo "/system/app/AirGlance/AirGlance\.apk u:object_r:system_file:s0"
            echo "/system/app/LiveDrawing u:object_r:system_file:s0"
            echo "/system/app/LiveDrawing/LiveDrawing\.apk u:object_r:system_file:s0"
            echo "/system/etc/default-permissions/default-permissions-com\.samsung\.android\.service\.aircommand\.xml u:object_r:system_file:s0"
            echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.app\.readingglass\.xml u:object_r:system_file:s0"
            echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.service\.aircommand\.xml u:object_r:system_file:s0"
            echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.service\.airviewdictionary\.xml u:object_r:system_file:s0"
            echo "/system/etc/sysconfig/airviewdictionaryservice\.xml u:object_r:system_file:s0"
            echo "/system/etc/public\.libraries-smps\.samsung\.txt u:object_r:system_file:s0"
            echo "/system/lib/libsmpsft\.smps\.samsung\.so u:object_r:system_lib_file:s0"
            echo "/system/lib64/libsmpsft\.smps\.samsung\.so u:object_r:system_lib_file:s0"
            echo "/system/media/audio/pensounds u:object_r:system_file:s0"
            echo "/system/media/audio/pensounds/smpsdata1\.dat u:object_r:system_file:s0"
            echo "/system/media/audio/pensounds/smpsdata2\.dat u:object_r:system_file:s0"
            echo "/system/media/audio/pensounds/smpsdata3\.dat u:object_r:system_file:s0"
            echo "/system/media/audio/pensounds/smpsdatae1\.dat u:object_r:system_file:s0"
            echo "/system/priv-app/AirCommand u:object_r:system_file:s0"
            echo "/system/priv-app/AirCommand/AirCommand\.apk u:object_r:system_file:s0"
            echo "/system/priv-app/AirReadingGlass u:object_r:system_file:s0"
            echo "/system/priv-app/AirReadingGlass/AirReadingGlass\.apk u:object_r:system_file:s0"
            echo "/system/priv-app/SmartEye u:object_r:system_file:s0"
            echo "/system/priv-app/SmartEye/SmartEye\.apk u:object_r:system_file:s0"
        } >> "$WORK_DIR/configs/file_context-system"
    fi
    if ! grep -q "AirReadingGlass" "$WORK_DIR/configs/fs_config-system"; then
        {
            echo "system/app/AirGlance 0 0 755 capabilities=0x0"
            echo "system/app/AirGlance/AirGlance.apk 0 0 644 capabilities=0x0"
            echo "system/app/LiveDrawing 0 0 755 capabilities=0x0"
            echo "system/app/LiveDrawing/LiveDrawing.apk 0 0 644 capabilities=0x0"
            echo "system/etc/default-permissions/default-permissions-com.samsung.android.service.aircommand.xml 0 0 644 capabilities=0x0"
            echo "system/etc/permissions/privapp-permissions-com.samsung.android.app.readingglass.xml 0 0 644 capabilities=0x0"
            echo "system/etc/permissions/privapp-permissions-com.samsung.android.service.aircommand.xml 0 0 644 capabilities=0x0"
            echo "system/etc/permissions/privapp-permissions-com.samsung.android.service.airviewdictionary.xml 0 0 644 capabilities=0x0"
            echo "system/etc/sysconfig/airviewdictionaryservice.xml 0 0 644 capabilities=0x0"
            echo "system/etc/public.libraries-smps.samsung.txt 0 0 644 capabilities=0x0"
            echo "system/lib/libsmpsft.smps.samsung.so 0 0 644 capabilities=0x0"
            echo "system/lib64/libsmpsft.smps.samsung.so 0 0 644 capabilities=0x0"
            echo "system/media/audio/pensounds 0 0 755 capabilities=0x0"
            echo "system/media/audio/pensounds/smpsdata1.dat 0 0 644 capabilities=0x0"
            echo "system/media/audio/pensounds/smpsdata2.dat 0 0 644 capabilities=0x0"
            echo "system/media/audio/pensounds/smpsdata3.dat 0 0 644 capabilities=0x0"
            echo "system/media/audio/pensounds/smpsdatae1.dat 0 0 644 capabilities=0x0"
            echo "system/priv-app/AirCommand 0 0 755 capabilities=0x0"
            echo "system/priv-app/AirCommand/AirCommand.apk 0 0 644 capabilities=0x0"
            echo "system/priv-app/AirReadingGlass 0 0 755 capabilities=0x0"
            echo "system/priv-app/AirReadingGlass/AirReadingGlass.apk 0 0 644 capabilities=0x0"
            echo "system/priv-app/SmartEye 0 0 755 capabilities=0x0"
            echo "system/priv-app/SmartEye/SmartEye.apk 0 0 644 capabilities=0x0"
        } >> "$WORK_DIR/configs/fs_config-system"
    fi
else
    echo "Target device is not an Ultra variant. Ignoring"
fi
