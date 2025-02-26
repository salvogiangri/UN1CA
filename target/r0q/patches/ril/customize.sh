if ! grep -q "firmware/kor" "$WORK_DIR/configs/file_context-vendor"; then
    {
        echo "/vendor/etc/init/ril_firmware\.rc u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/plmn_delta_attaio\.bin u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/plmn_delta_usagsm\.bin u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/vintf/manifest/vendor\.samsung\.hardware\.radio_manifest_1_31\.xml u:object_r:vendor_configs_file:s0"
        echo "/vendor/etc/vintf/manifest/vendor\.samsung\.hardware\.sehradio_manifest_1_31\.xml u:object_r:vendor_configs_file:s0"
        echo "/vendor/firmware/kor u:object_r:vendor_firmware_file:s0"
        echo "/vendor/firmware/kor/libril_sem\.so u:object_r:vendor_file:s0"
        echo "/vendor/firmware/kor/libsec-ril\.so u:object_r:vendor_file:s0"
        echo "/vendor/firmware/kor/rild u:object_r:rild_exec:s0"
        echo "/vendor/firmware/kor/secril_config_svc u:object_r:secril_config_svc_exec:s0"
    } >> "$WORK_DIR/configs/file_context-vendor"
fi
if ! grep -q "firmware/kor" "$WORK_DIR/configs/fs_config-vendor"; then
    {
        echo "/vendor/etc/init/ril_firmware.rc 0 0 644 capabilities=0x0"
        echo "/vendor/etc/plmn_delta_attaio.bin 0 0 644 capabilities=0x0"
        echo "/vendor/etc/plmn_delta_usagsm.bin 0 0 644 capabilities=0x0"
        echo "/vendor/etc/vintf/manifest/vendor.samsung.hardware.radio_manifest_1_31.xml 0 0 644 capabilities=0x0"
        echo "/vendor/etc/vintf/manifest/vendor.samsung.hardware.sehradio_manifest_1_31.xml 0 0 644 capabilities=0x0"
        echo "/vendor/firmware/kor 0 2000 755 capabilities=0x0"
        echo "/vendor/firmware/kor/libril_sem.so 0 0 644 capabilities=0x0"
        echo "/vendor/firmware/kor/libsec-ril.so 0 0 644 capabilities=0x0"
        echo "/vendor/firmware/kor/rild 0 2000 755 capabilities=0x0"
        echo "/vendor/firmware/kor/secril_config_svc 0 2000 755 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-vendor"
fi
if ! grep -q "vendor_firmware_file (file (mounton" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
    echo "(allow init_30_0 vendor_firmware_file (file (mounton)))" >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
fi
