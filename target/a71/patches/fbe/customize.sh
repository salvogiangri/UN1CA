LOG "- Patching /vendor/etc/fstab.default"
EVAL "sed -i \"/[[:space:]]\/data[[:space:]]/ s|fileencryption=ice|fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,keydirectory=/metadata/vold/metadata_encryption,sysfs_path=/sys/devices/platform/soc/1d84000.ufshc|g\" \"$WORK_DIR/vendor/etc/fstab.default\""
