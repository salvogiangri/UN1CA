# Patched GoodLock Manager @corsicanu
# https://github.com/corsicanu/goodlock_dump
DOWNLOAD_FILE "https://github.com/corsicanu/goodlock_dump/raw/main/GoodLock_patched.apk" \
    "$WORK_DIR/system/system/preload/GoodLock/GoodLock.apk"

# Samsung Internet Browser
# https://play.google.com/store/apps/details?id=com.sec.android.app.sbrowser
if [[ "$TARGET_CODENAME" != "m51" ]]; then
    DOWNLOAD_FILE "$(GET_GALAXY_STORE_DOWNLOAD_URL "com.sec.android.app.sbrowser")" \
        "$WORK_DIR/system/system/preload/SBrowser/SBrowser.apk"
fi

echo "- Updating fs_config and file_context for /system/preload..."

# Remove existing preload entries
sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system"
sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"

find "$WORK_DIR/system/system/preload" -print \
  | sed "s|^$WORK_DIR/system/||" \
  | while read -r FILE; do
      ABS="$WORK_DIR/system/$FILE"
      if [ -d "$ABS" ]; then
          echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
      elif [ -f "$ABS" ]; then
          echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
      fi

      ESCAPED="$(echo "$FILE" | sed 's|\.|\\.|g')"
      echo "/$ESCAPED u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
  done

# Update vpl_apks_count_list.txt
rm -f "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"

find "$WORK_DIR/system/system/preload" -name "*.apk" | sort \
  | sed "s|^$WORK_DIR/system/||" \
  | while read -r FILE; do
      echo "$FILE" >> "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
  done