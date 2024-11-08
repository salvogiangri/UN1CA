SKIPUNZIP=1

# [
SET_PROP()
{
    local PROP="$1"
    local VALUE="$2"
    local FILE="$3"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        PROP="$(echo -n "$PROP" | sed 's/=//g')"
        if grep -Fq "$PROP" "$FILE"; then
            echo "Deleting \"$PROP\" prop in $FILE" | sed "s.$WORK_DIR..g"
            sed -i "/^$PROP/d" "$FILE"
        fi
    else
        if grep -Fq "$PROP" "$FILE"; then
            local LINES

            echo "Replacing \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            LINES="$(sed -n "/^${PROP}\b/=" "$FILE")"
            for l in $LINES; do
                sed -i "$l c${PROP}=${VALUE}" "$FILE"
            done
        else
            echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            if ! grep -q "Added by scripts" "$FILE"; then
                echo "# Added by scripts/internal/apply_modules.sh" >> "$FILE"
            fi
            echo "$PROP=$VALUE" >> "$FILE"
        fi
    fi
}
# ]

SET_PROP "ro.unica.version" "$ROM_VERSION" "$WORK_DIR/system/system/build.prop"
SET_PROP "ro.unica.codename" "$ROM_CODENAME" "$WORK_DIR/system/system/build.prop"

if $ROM_IS_OFFICIAL; then
    SET_PROP "ro.unica.timestamp" "$ROM_BUILD_TIMESTAMP" "$WORK_DIR/system/system/build.prop"

    cp -a --preserve=all "$SRC_DIR/unica/mods/choidujour/system/"* "$WORK_DIR/system/system"

    if ! grep -q "choidujour" "$WORK_DIR/configs/file_context-system"; then
        {
            echo "/system/etc/default-permissions/default-permissions-io\.mesalabs\.choidujour\.xml u:object_r:system_file:s0"
            echo "/system/etc/permissions/privapp-permissions-io\.mesalabs\.choidujour\.xml u:object_r:system_file:s0"
            echo "/system/priv-app/ChoiDujour u:object_r:system_file:s0"
            echo "/system/priv-app/ChoiDujour/ChoiDujour\.apk u:object_r:system_file:s0"
        } >> "$WORK_DIR/configs/file_context-system"
    fi
    if ! grep -q "choidujour" "$WORK_DIR/configs/fs_config-system"; then
        {
            echo "system/etc/default-permissions/default-permissions-io.mesalabs.choidujour.xml 0 0 644 capabilities=0x0"
            echo "system/etc/permissions/privapp-permissions-io.mesalabs.choidujour.xml 0 0 644 capabilities=0x0"
            echo "system/priv-app/ChoiDujour 0 0 755 capabilities=0x0"
            echo "system/priv-app/ChoiDujour/ChoiDujour.apk 0 0 644 capabilities=0x0"
        } >> "$WORK_DIR/configs/fs_config-system"
    fi

    CERT_NAME="aosp_testkey"
    [ -f "$SRC_DIR/unica/security/unica_ota.x509.pem" ] && CERT_NAME="unica_ota"

    rm "$WORK_DIR/system/system/etc/security/otacerts.zip"
    cd "$SRC_DIR" ; zip -q "$WORK_DIR/system/system/etc/security/otacerts.zip" "./unica/security/$CERT_NAME.x509.pem" ; cd - &> /dev/null
else
    echo "Build is not official. Ignoring"
fi
