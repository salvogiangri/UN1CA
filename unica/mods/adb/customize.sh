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

SET_PROP_IF_DIFF() {
    local PROP="$1"
    local EXPECTED="$2"
    local FILE="$3"

    [ -f "$FILE" ] || return 0

    local CURRENT="$(GET_PROP "$PROP" "$FILE")"
    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || SET_PROP "$PROP" "$EXPECTED" "$FILE"
}
# ]

SET_PROP_IF_DIFF "ro.adb.secure" "0" "$WORK_DIR/vendor/build.prop"
SET_PROP_IF_DIFF "persist.sys.usb.config" "mtp,adb" "$WORK_DIR/vendor/build.prop"
SET_PROP_IF_DIFF "ro.adb.secure" "0" "$WORK_DIR/vendor/default.prop"
SET_PROP_IF_DIFF "persist.sys.usb.config" "mtp,adb" "$WORK_DIR/vendor/default.prop"
SET_PROP_IF_DIFF "persist.sys.usb.config" "mtp,adb" "$WORK_DIR/vendor/odm_dlkm/etc/build.prop"
SET_PROP_IF_DIFF "persist.sys.usb.config" "mtp,adb" "$WORK_DIR/system_dlkm/etc/build.prop"
SET_PROP_IF_DIFF "persist.sys.usb.config" "mtp,adb" "$WORK_DIR/vendor_dlkm/etc/build.prop"

if [ -f "$WORK_DIR/vendor/etc/init/hw/init.target.rc" ]; then
    if ! grep -q "persist.vendor.radio.port_index" "$WORK_DIR/vendor/etc/init/hw/init.target.rc"; then
        {
            echo ""
            echo "on property:persist.vendor.radio.port_index=\"\""
            echo "    setprop sys.usb.config adb"
        } >> "$WORK_DIR/vendor/etc/init/hw/init.target.rc"
    fi
fi
