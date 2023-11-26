#====================================================
# FILE:         assistant.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Fix Google Assistant
#====================================================

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"
# ]

echo "Applying Google Assistant fix"

if [ ! -f "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON.apk" ]; then
    rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
    mkdir -p "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON"
    cp -a --preserve=all \
        "$SRC_DIR/target/a52sxq/patches/assistant/HotwordEnrollmentOKGoogleEx3HEXAGON.apk" \
        "$WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON.apk"
    sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
    sed -i "s/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
fi

if [ ! -f "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx3HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON.apk" ]; then
    rm -rf "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
    mkdir -p "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx3HEXAGON"
    cp -a --preserve=all \
        "$SRC_DIR/target/a52sxq/patches/assistant/HotwordEnrollmentXGoogleEx3HEXAGON.apk" \
        "$WORK_DIR/product/priv-app/HotwordEnrollmentXGoogleEx3HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON.apk"
    sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/file_context-product"
    sed -i "s/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx3HEXAGON/g" "$WORK_DIR/configs/fs_config-product"
fi

exit 0
