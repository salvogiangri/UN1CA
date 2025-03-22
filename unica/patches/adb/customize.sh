if [ -f "$WORK_DIR/vendor/etc/init/hw/init.target.rc" ]; then
    if ! grep -q "persist.vendor.radio.port_index" "$WORK_DIR/vendor/etc/init/hw/init.target.rc"; then
        {
            echo ""
            echo "on property:persist.vendor.radio.port_index=\"\""
            echo "    setprop sys.usb.config adb"
        } >> "$WORK_DIR/vendor/etc/init/hw/init.target.rc"
    fi
fi
