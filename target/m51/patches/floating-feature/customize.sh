
cp -f --preserve=all \
    "$SRC_DIR/target/m51/patches/floating-feature/floating_feature.xml" \
    "$WORK_DIR/system/system/etc/floating_feature.xml"
SET_METADATA "system" "system/etc/floating_feature.xml" 0 0 644 "u:object_r:system_file:s0"
