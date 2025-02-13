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

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

echo "Remove NXP SecureElement service"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/bin/hw/android.hardware.secure_element@1.1-service"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/init/android.hardware.secure_element@1.1-service.rc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/libese-nxp.conf"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/ese_spi_nxp.so"

echo "Add FeliCa NFC service"
if ! grep -q "nfc_nci_fn" "$WORK_DIR/configs/file_context-vendor"; then
    {
        echo "/vendor/bin/hw/sec\.android\.hardware\.nfc@1\.2-service u:object_r:hal_nfc_default_exec:s0"
        echo "/vendor/etc/init/multi\.android\.hardware\.nfc@1\.2-service\.rc u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/sec_senn82ab_rfreg\.bin u:object_r:vendor_configs_file:s0"
        echo "/vendor/firmware/sec_senn82ab_firmware\.bin u:object_r:vendor_firmware_file:s0"
        echo "/vendor/lib64/nfc_nci_fn\.so u:object_r:vendor_file:s0"
    } >> "$WORK_DIR/configs/file_context-vendor"
fi
if ! grep -q "nfc_nci_fn" "$WORK_DIR/configs/fs_config-vendor"; then
    {
        echo "vendor/bin/hw/sec.android.hardware.nfc@1.2-service 0 2000 755 capabilities=0x0"
        echo "vendor/etc/init/multi.android.hardware.nfc@1.2-service.rc 0 0 644 capabilities=0x0"
        echo "vendor/etc/sec_senn82ab_rfreg.bin 0 0 644 capabilities=0x0"
        echo "vendor/firmware/sec_senn82ab_firmware.bin 0 0 644 capabilities=0x0"
        echo "vendor/lib64/nfc_nci_fn.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-vendor"
fi

echo "Set props for different variants"
if ! grep -Eq "SC-51A|SCG01|SM-G981N|SM-G9810" "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"; then
    {
        echo ""
        echo "on property:ro.boot.em.model=SC-51A"
        echo "    setprop ro.vendor.nfc.feature.chipname \"SENN82AB\""
        echo "    setprop ro.vendor.nfc.support.advancedsetting \"false\""
        echo "    setprop ro.vendor.nfc.support.uicc \"false\""
        echo "    setprop ro.vendor.nfc.support.nonaid \"false\""
        echo ""
        echo "on property:ro.boot.em.model=SCG01"
        echo "    setprop ro.vendor.nfc.feature.chipname \"SENN82AB\""
        echo "    setprop ro.vendor.nfc.support.advancedsetting \"false\""
        echo "    setprop ro.vendor.nfc.support.uicc \"false\""
        echo "    setprop ro.vendor.nfc.support.nonaid \"false\""
        echo ""
        echo "on property:ro.boot.em.model=SM-G981N"
        echo "    setprop ro.boot.product.hardware.sku \"sn110t\""
        echo "    setprop ro.vendor.nfc.feature.chipname \"NXP_SN100U\""
        echo "    setprop ro.vendor.nfc.support.advancedsetting \"true\""
        echo "    setprop ro.vendor.nfc.support.uicc \"true\""
        echo "    setprop ro.vendor.nfc.info.antpos \"1\""
        echo ""
        echo "on property:ro.boot.em.model=SM-G9810"
        echo "    setprop ro.boot.product.hardware.sku \"sn110t\""
        echo "    setprop ro.vendor.nfc.feature.chipname \"NXP_SN100U\""
        echo "    setprop ro.vendor.nfc.support.advancedsetting \"true\""
        echo "    setprop ro.vendor.nfc.support.uicc \"true\""
        echo "    setprop ro.vendor.nfc.info.antpos \"1\""
    } >> "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc"
fi