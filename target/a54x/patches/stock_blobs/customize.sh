SKIPUNZIP=1

# [
ADD_TO_WORK_DIR()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    mkdir -p "$WORK_DIR/$(dirname "$FILE_PATH")"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$FILE_PATH" "$WORK_DIR/$FILE_PATH"

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
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

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

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
ADD_TO_WORK_DIR "system" "system/etc/vintf/compatibility_matrix.device.xml" 0 0 644 "u:object_r:system_file:s0"

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.cover.flip.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.pocketmode_level33.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.sensorhub_level29.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.sec.feature.wirelesscharger_authentication.xml"
echo "Add stock system features"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketsensitivitymode_level4.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/etc/permissions/com.sec.feature.sensorhub_level100.xml" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock audio policy"
ADD_TO_WORK_DIR "system" "system/etc/stage_policy.conf" 0 0 644 "u:object_r:system_file:s0"
