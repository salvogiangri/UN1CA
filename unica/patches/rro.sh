#====================================================
# FILE:         rro.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Replace /product RRO configs with
#               target ones
#====================================================

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
APKTOOL_DIR="$OUT_DIR/apktool"

source "$OUT_DIR/config.sh"
# ]

if [[ -d "$SRC_DIR/target/$TARGET_CODENAME/patches/overlay" ]]; then
    bash -e "$SRC_DIR/scripts/apktool.sh" d -f "/product/overlay/framework-res__auto_generated_rro_product.apk"

    echo "Applying stock overlay configs"
    rm -f "$APKTOOL_DIR/product/overlay/framework-res__auto_generated_rro_product.apk/res/values/public.xml"
    cp -a --preserve=all \
        "$SRC_DIR/target/$TARGET_CODENAME/patches/overlay/"* \
        "$APKTOOL_DIR/product/overlay/framework-res__auto_generated_rro_product.apk/res"

    bash -e "$SRC_DIR/scripts/apktool.sh" b "/product/overlay/framework-res__auto_generated_rro_product.apk"
fi

exit 0
