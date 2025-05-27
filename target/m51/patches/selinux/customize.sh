SKIPUNZIP=1

# [
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

echo "Removing unsupported SELinux entries"
sed -i "/hal_dsms_default/d" "$WORK_DIR/system/system/system_ext/etc/selinux/mapping/30.0.cil"

echo "Fooling SELinux platform version"
IFS_SOURCE=':' read -a SOURCE_FIRMWARE <<< "$SOURCE_FIRMWARE"
MODEL_SOURCE=$(echo -n "${SOURCE_FIRMWARE[0]}" | cut -d "/" -f 1)
REGION_SOURCE=$(echo -n "${SOURCE_FIRMWARE[0]}" | cut -d "/" -f 2)

SET_PROP "VE" "$(GET_PROP "VE" "$FW_DIR/${MODEL}_${REGION}/vendor/etc/selinux/vendor_sepolicy_version")" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
SET_PROP "BD" "$(GET_PROP "BD" "$FW_DIR/${MODEL}_${REGION}/vendor/etc/selinux/vendor_sepolicy_version")" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
