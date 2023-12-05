SKIPUNZIP=1

LINE=$(sed -n "/^\/dev\/block\/bootdevice\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.qcom")
sed -i -e "${LINE}s/,fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized//g" \
    -e "${LINE}s/,keydirectory=\/metadata\/vold\/metadata_encryption//g" \
    -e "${LINE}s/,inlinecrypt//g" \
    -e "${LINE}s/,wrappedkey//g" \
    -e "${LINE}s/,,/,/g" "$WORK_DIR/vendor/etc/fstab.qcom"
