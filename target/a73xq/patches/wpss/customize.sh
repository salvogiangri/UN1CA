if ! grep -q "vendor_firmware_file (file (mounton" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
    echo "(allow init_30_0 vendor_firmware_file (file (mounton)))" >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
fi
