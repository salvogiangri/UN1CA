SKIPUNZIP=1

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

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

echo "Fix Google Assistant"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/product/priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM4" "$WORK_DIR/product/priv-app"
rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/product/priv-app/HotwordEnrollmentXGoogleEx4CORTEXM4" "$WORK_DIR/product/priv-app"
sed -i "s/HotwordEnrollmentXGoogleEx4CORTEXM55/HotwordEnrollmentXGoogleEx4CORTEXM4/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentXGoogleEx4CORTEXM55/HotwordEnrollmentXGoogleEx4CORTEXM4/g" "$WORK_DIR/configs/fs_config-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4CORTEXM55/HotwordEnrollmentOKGoogleEx4CORTEXM4/g" "$WORK_DIR/configs/file_context-product"
sed -i "s/HotwordEnrollmentOKGoogleEx4CORTEXM55/HotwordEnrollmentOKGoogleEx4CORTEXM4/g" "$WORK_DIR/configs/fs_config-product"

echo "Add stock vintf manifest"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/vintf/compatibility_matrix.device.xml" \
    "$WORK_DIR/system/system/etc/vintf/compatibility_matrix.device.xml"

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.flip.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.pocketmode_level33.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.sensorhub_level29.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.wirelesscharger_authentication.xml"
echo "Add stock system features"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/permissions/com.sec.feature.pocketsensitivitymode_level4.xml" \
    "$WORK_DIR/system/system/etc/permissions/com.sec.feature.pocketsensitivitymode_level4.xml"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/permissions/com.sec.feature.sensorhub_level100.xml" \
    "$WORK_DIR/system/system/etc/permissions/com.sec.feature.sensorhub_level100.xml"
if ! grep -q "pocketsensitivitymode" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/etc/permissions/com\.sec\.feature\.pocketsensitivitymode_level4\.xml u:object_r:system_file:s0"
        echo "/system/etc/permissions/com\.sec\.feature\.sensorhub_level100\.xml u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "pocketsensitivitymode" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/etc/permissions/com.sec.feature.pocketsensitivitymode_level4.xml 0 0 644 capabilities=0x0"
        echo "system/etc/permissions/com.sec.feature.sensorhub_level100.xml 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi

echo "Add stock audio policy"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/etc/stage_policy.conf" \
    "$WORK_DIR/system/system/etc/stage_policy.conf"
