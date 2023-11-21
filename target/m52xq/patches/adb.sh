#====================================================
# FILE:         adb.sh
# AUTHOR:       BlackMesa123, AgentFabulous
# DESCRIPTION:  Enabled ADB at boot
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"
# ]

echo "Enabling ADB at boot"

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
