SKIPUNZIP=1

cp -a --preserve=all "$SRC_DIR/target/$TARGET_CODENAME/patches/mainline-fix/product" "$APKTOOL_DIR"
if ! grep -q "MainlineFix" "$WORK_DIR/configs/file_context-product"; then
    {
        echo "/product/overlay/MainlineFix\.apk u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-product"
fi
if ! grep -q "MainlineFix" "$WORK_DIR/configs/fs_config-product"; then
    {
        echo "product/overlay/MainlineFix.apk 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-product"
fi
