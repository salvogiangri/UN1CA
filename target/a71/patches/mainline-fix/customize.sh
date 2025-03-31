SKIPUNZIP=1

cp -a --preserve=all "$SRC_DIR/target/$TARGET_CODENAME/patches/mainline-fix/product" "$APKTOOL_DIR"
SET_METADATA "product" "overlay/MainlineFix.apk" 0 0 644 "u:object_r:system_file:s0"
