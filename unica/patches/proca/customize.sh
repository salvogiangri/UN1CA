PATCHED=false

if [ ! -f "$WORK_DIR/kernel/boot.img" ]; then
    echo "File not found: $WORK_DIR/kernel/boot.img"
    exit 1
fi

[ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cp -a --preserve=all "$WORK_DIR/kernel/boot.img" "$TMP_DIR/boot.img"
MKBOOTIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/boot.img" --out "$TMP_DIR/out" --format mkbootimg)"

if [ ! -f "$TMP_DIR/out/kernel" ]; then
    echo -e "Failed to extract boot.img:\n$MKBOOTIMG_ARGS"
    exit 1
fi

if [[ "$(file -b "$TMP_DIR/out/kernel")" == "Linux kernel ARM64"* ]]; then
    PROCA_CONFIG_ADDR="$(xxd -p -l "4" --skip "40" "$TMP_DIR/out/kernel")"
    if [[ "$PROCA_CONFIG_ADDR" != "00000000" ]] || [[ "$PROCA_CONFIG_ADDR" != "efecefec" ]]; then
        printf "\xef\xec\xef\xec" | dd of="$TMP_DIR/out/kernel" bs=1 seek=40 count=4 conv=notrunc &> /dev/null
        PATCHED=true
    fi

    if grep -q -w "proca_config" "$TMP_DIR/out/kernel"; then
        sed -i "s/proca_config\x00/fuck_u_sammy\x00/g" "$TMP_DIR/out/kernel"
        PATCHED=true
    fi

    if $PATCHED; then
        eval "mkbootimg $MKBOOTIMG_ARGS -o $TMP_DIR/new-boot.img"
        echo -n "SEANDROIDENFORCE" >> "$TMP_DIR/new-boot.img"
        mv -f "$TMP_DIR/new-boot.img" "$WORK_DIR/kernel/boot.img"
    fi
else
    echo -e "Ignoring kernel image ($(file -b "$TMP_DIR/out/kernel"))"
fi

rm -rf "$TMP_DIR"
