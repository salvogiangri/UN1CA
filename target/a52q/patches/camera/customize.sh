if ! grep -q "Camera End" "$WORK_DIR/vendor/ueventd.rc"; then
    echo "" >> "$WORK_DIR/vendor/ueventd.rc"
    cat "$SRC_DIR/target/a52q/patches/camera/ueventd" >> "$WORK_DIR/vendor/ueventd.rc"
fi
