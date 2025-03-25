# Patched GoodLock Manager @corsicanu
# https://github.com/corsicanu/goodlock_dump
DOWNLOAD_FILE "https://github.com/corsicanu/goodlock_dump/raw/main/GoodLock_patched.apk" \
    "$WORK_DIR/system/system/preload/GoodLock/GoodLock.apk"

# Samsung Internet Browser
# https://play.google.com/store/apps/details?id=com.sec.android.app.sbrowser
if [[ "$TARGET_CODENAME" != "a71" ]]; then
    DOWNLOAD_FILE "$(GET_GALAXY_STORE_DOWNLOAD_URL "com.sec.android.app.sbrowser")" \
        "$WORK_DIR/system/system/preload/SBrowser/SBrowser.apk"
fi

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
