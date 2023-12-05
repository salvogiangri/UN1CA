SKIPUNZIP=1

sed -i \
    "$(sed -n "/persist.sys.usb.config/=" "$WORK_DIR/vendor/default.prop") cpersist.sys.usb.config=mtp,adb" \
    "$WORK_DIR/vendor/default.prop"

if ! grep -q "persist.vendor.radio.port_index" "$WORK_DIR/vendor/etc/init/hw/init.target.rc"; then
    {
        echo ""
        echo "on property:persist.vendor.radio.port_index=\"\""
        echo "    setprop sys.usb.config adb"
    } >> "$WORK_DIR/vendor/etc/init/hw/init.target.rc"
fi
