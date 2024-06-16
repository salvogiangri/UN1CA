SKIPUNZIP=1

TBF_TARGETS="a52q a71 a72q"

if echo "$TBF_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    rm -rf "$WORK_DIR/system/system/priv-app/PhotoEditor_AIFull"
    sed -i "s/PhotoEditor_AIFull/PhotoEditor_Full/g" "$WORK_DIR/configs/file_context-system"
    sed -i "s/PhotoEditor_AIFull/PhotoEditor_Full/g" "$WORK_DIR/configs/fs_config-system"
    cp -a --preserve=all "$SRC_DIR/unica/patches/photoeditor/system/"* "$WORK_DIR/system/system"
fi
