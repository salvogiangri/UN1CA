SKIPUNZIP=1

if $SOURCE_HAS_HW_MDNIE; then
    if ! $TARGET_HAS_HW_MDNIE; then
        [ ! -d "$APKTOOL_DIR/system/framework/framework.jar" ] && bash "$SRC_DIR/scripts/apktool.sh" d "/system/framework/framework.jar"
        cd "$APKTOOL_DIR/system/framework/framework.jar"
        PATCH="$SRC_DIR/unica/patches/mdnie/framework.jar/0001-Disable-HW-mDNIe.patch"
        OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
        cd - &> /dev/null

        [ ! -d "$APKTOOL_DIR/system/framework/services.jar" ] && bash "$SRC_DIR/scripts/apktool.sh" d "/system/framework/services.jar"
        cd "$APKTOOL_DIR/system/framework/services.jar"
        PATCH="$SRC_DIR/unica/patches/mdnie/services.jar/0001-Disable-HW-mDNIe.patch"
        OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
        cd - &> /dev/null
    fi
fi
