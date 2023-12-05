SKIPUNZIP=1

if [[ "$SOURCE_VNDK_VERSION" != "$TARGET_VNDK_VERSION" ]]; then
    if $TARGET_HAS_SYSTEM_EXT; then
        SYS_EXT_DIR="$WORK_DIR/system_ext"
        PARTITION="system_ext"
    else
        SYS_EXT_DIR="$WORK_DIR/system/system/system_ext"
        PARTITION="system"
    fi

    if [ ! -f "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex" ]; then
        rm -f "$SYS_EXT_DIR/apex/com.android.vndk.v$SOURCE_VNDK_VERSION.apex"
        if [ "$TARGET_VNDK_VERSION" -eq 30 ]; then
            cat "$SRC_DIR/unica/packages/vndk/30/com.android.vndk.v30.apex.00" \
                "$SRC_DIR/unica/packages/vndk/30/com.android.vndk.v30.apex.01" \
                "$SRC_DIR/unica/packages/vndk/30/com.android.vndk.v30.apex.02" > "$SYS_EXT_DIR/apex/com.android.vndk.v30.apex"
        else
            cp --preserve=all \
                "$SRC_DIR/unica/packages/vndk/$TARGET_VNDK_VERSION/com.android.vndk.v$TARGET_VNDK_VERSION.apex" "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex"
        fi
        sed -i "s/com\\\.android\\\.vndk\\\.v$SOURCE_VNDK_VERSION/com\\\.android\\\.vndk\\\.v$TARGET_VNDK_VERSION/g" \
            "$WORK_DIR/configs/file_context-$PARTITION"
        sed -i "s/com.android.vndk.v$SOURCE_VNDK_VERSION/com.android.vndk.v$TARGET_VNDK_VERSION/g" \
            "$WORK_DIR/configs/fs_config-$PARTITION"

        sed -i "s/version>$SOURCE_VNDK_VERSION/version>$TARGET_VNDK_VERSION/g" "$SYS_EXT_DIR/etc/vintf/manifest.xml"
    else
        echo "VNDK v$TARGET_VNDK_VERSION apex is already in place. Ignoring"
    fi
else
    echo "SOURCE_VNDK_VERSION and TARGET_VNDK_VERSION are the same. Ignoring"
fi
