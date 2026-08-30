if ! grep -q "1.5::IRadio/" "$WORK_DIR/vendor/etc/vintf/manifest.xml"; then
    LOG "- Patching /vendor/etc/vintf/manifest.xml"
    EVAL "sed -i \"s/1.4::IRadio\//1.5::IRadio\//g\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
fi
