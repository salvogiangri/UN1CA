SKIPUNZIP=1

if [[ -d "$SRC_DIR/target/$TARGET_CODENAME/overlay" ]]; then
    bash -e "$SRC_DIR/scripts/apktool.sh" d -f "/product/overlay/framework-res__auto_generated_rro_product.apk"

    echo "Applying stock overlay configs"
    rm -rf "$APKTOOL_DIR/product/overlay/framework-res__auto_generated_rro_product.apk/res"
    cp -a --preserve=all \
        "$SRC_DIR/target/$TARGET_CODENAME/overlay" \
        "$APKTOOL_DIR/product/overlay/framework-res__auto_generated_rro_product.apk/res"
fi
