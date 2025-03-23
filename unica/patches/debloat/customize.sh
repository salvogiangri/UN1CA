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
