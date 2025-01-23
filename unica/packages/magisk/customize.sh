SKIPUNZIP=1

# [
MAGISK_MANAGER_APK="https://github.com/topjohnwu/magisk-files/raw/020c7134ff62000744480d03a8be5d8fbfdd226b/app-release.apk"

PATCH_KERNEL()
{
    local KERNEL_IMG="boot.img"
    [ -f "$WORK_DIR/kernel/init_boot.img" ] && KERNEL_IMG="init_boot.img"

    if [ ! -f "$WORK_DIR/kernel/$KERNEL_IMG" ]; then
        echo "File not found: $KERNEL_IMG"
        exit 1
    fi

    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    echo "Downloading Magisk.apk"
    curl -L -s -o "$TMP_DIR/Magisk.apk" "$MAGISK_MANAGER_APK"

    unzip -q -j "$TMP_DIR/Magisk.apk" "assets/boot_patch.sh" -d "$TMP_DIR"
    unzip -q -j "$TMP_DIR/Magisk.apk" "assets/stub.apk" -d "$TMP_DIR"
    unzip -q -j "$TMP_DIR/Magisk.apk" "lib/x86_64/libmagiskboot.so" -d "$TMP_DIR" \
        && mv -f "$TMP_DIR/libmagiskboot.so" "$TMP_DIR/magiskboot" \
        && chmod 755 "$TMP_DIR/magiskboot"
    unzip -q -j "$TMP_DIR/Magisk.apk" "lib/armeabi-v7a/libmagisk32.so" -d "$TMP_DIR" \
        && mv -f "$TMP_DIR/libmagisk32.so" "$TMP_DIR/magisk32"
    unzip -q -j "$TMP_DIR/Magisk.apk" "lib/arm64-v8a/libmagisk64.so" -d "$TMP_DIR" \
        && mv -f "$TMP_DIR/libmagisk64.so" "$TMP_DIR/magisk64"
    unzip -q -j "$TMP_DIR/Magisk.apk" "lib/arm64-v8a/libmagiskinit.so" -d "$TMP_DIR" \
        && mv -f "$TMP_DIR/libmagiskinit.so" "$TMP_DIR/magiskinit"

    {
        echo 'ui_print() { echo "$1"; }'
        echo 'abort() { ui_print "$1"; exit 1; }'
        echo 'api_level_arch_detect() { true; }'
        echo 'KEEPFORCEENCRYPT=true'
        echo 'KEEPVERITY=true'
        echo 'PREINITDEVICE=cache'
    } > "$TMP_DIR/util_functions.sh"

    echo "Patching $KERNEL_IMG"
    cp -a --preserve=all "$WORK_DIR/kernel/$KERNEL_IMG" "$TMP_DIR/$KERNEL_IMG"
    sh "$TMP_DIR/boot_patch.sh" "$TMP_DIR/$KERNEL_IMG" 2> /dev/null
    mv -f "$TMP_DIR/new-boot.img" "$WORK_DIR/kernel/$KERNEL_IMG"

    rm -rf "$TMP_DIR"
}

ADD_MANAGER_APK_TO_PRELOAD()
{
    local APK_PATH="system/preload/Magisk/Magisk.apk"

    echo "Adding Magisk.apk to preload apps"
    mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
    curl -L -s -o "$WORK_DIR/system/$APK_PATH" -z "$WORK_DIR/system/$APK_PATH" "$MAGISK_MANAGER_APK"

    sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system" \
        && sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"
    while read -r i; do
        FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
        [ -d "$i" ] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
        [ -f "$i" ] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
    done <<< "$(find "$WORK_DIR/system/system/preload")"

    rm -f "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
    while read -r i; do
        FILE="$(echo "$i" | sed "s.$WORK_DIR/system..")"
        echo "$FILE" >> "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
    done <<< "$(find "$WORK_DIR/system/system/preload" -name "*.apk" | sort)"
}
# ]

if $TARGET_INCLUDE_MAGISK; then
    PATCH_KERNEL
    ADD_MANAGER_APK_TO_PRELOAD
else
    echo "TARGET_INCLUDE_MAGISK is not enabled. Ignoring"
fi
