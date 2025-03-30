# Dexpreopt
for f in $(find "$WORK_DIR/product" -type d -name "oat"); do
    DELETE_FROM_WORK_DIR "product" "${f//$WORK_DIR\/product\//}"
done
for f in $(find "$WORK_DIR/system" -type d -name "oat"); do
    DELETE_FROM_WORK_DIR "system" "${f//$WORK_DIR\/system\//}"
done
DELETE_FROM_WORK_DIR "system" "system/etc/boot-image.bprof"
DELETE_FROM_WORK_DIR "system" "system/etc/boot-image.prof"
DELETE_FROM_WORK_DIR "system" "system/framework/arm"
DELETE_FROM_WORK_DIR "system" "system/framework/arm64"
for f in $(find "$WORK_DIR/system/system/framework" -type f -name "*.vdex"); do
    DELETE_FROM_WORK_DIR "system" "${f//$WORK_DIR\/system\//}"
done
if $TARGET_HAS_SYSTEM_EXT; then
    for f in $(find "$WORK_DIR/system_ext" -type d -name "oat"); do
        DELETE_FROM_WORK_DIR "system_ext" "${f//$WORK_DIR\/system_ext\//}"
    done
fi

# ROM & device-specific debloat list
[ -f "$SRC_DIR/unica/debloat.sh" ] && source "$SRC_DIR/unica/debloat.sh"
[ -f "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh" ] && source "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh"

for f in $ODM_DEBLOAT; do
    DELETE_FROM_WORK_DIR "odm" "$f"
done
for f in $PRODUCT_DEBLOAT; do
    DELETE_FROM_WORK_DIR "product" "$f"
done
for f in $SYSTEM_DEBLOAT; do
    DELETE_FROM_WORK_DIR "system" "$f"
done
for f in $SYSTEM_EXT_DEBLOAT; do
    DELETE_FROM_WORK_DIR "system_ext" "$f"
done
for f in $VENDOR_DEBLOAT; do
    DELETE_FROM_WORK_DIR "vendor" "$f"
done
