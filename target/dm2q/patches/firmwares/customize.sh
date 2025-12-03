LOG "- Adding GPU (Adreno 740) firmware"
LOG "- Adding Camera ICP firmware"  
LOG "- Adding Display EVASS firmware"

# Firmware files are automatically included from the vendor/firmware directory
# and configured via fs_config-vendor and file_context-vendor

# Patch SELinux to allow firmware mounting
if [ -f "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil" ]; then
    LOG "- Patching /vendor/etc/selinux/vendor_sepolicy.cil for firmware mounting"
    EVAL "echo \"(allow init_30_0 vendor_firmware_file (file (mounton)))\" >> \"$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil\""
fi
