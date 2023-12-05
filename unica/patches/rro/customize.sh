SKIPUNZIP=1

if [[ -d "$SRC_DIR/target/$TARGET_CODENAME/patches/overlay" ]]; then
    bash -e "$SRC_DIR/scripts/apktool.sh" d -f "/product/overlay/framework-res__auto_generated_rro_product.apk"

    echo "Applying stock overlay configs"
    rm -f "$APKTOOL_DIR/product/overlay/framework-res__auto_generated_rro_product.apk/res/values/public.xml"
    cp -a --preserve=all \
        "$SRC_DIR/target/$TARGET_CODENAME/patches/overlay/"* \
        "$APKTOOL_DIR/product/overlay/framework-res__auto_generated_rro_product.apk/res"
fi
