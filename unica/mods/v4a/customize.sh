LOG_STEP_IN "- Adding Viper4AndroidFX-RE"

CURL_AUTH_ARGS=""
if [ -n "${GITHUB_TOKEN:-}" ]; then CURL_AUTH_ARGS="-H Authorization: token $GITHUB_TOKEN"; fi

MODULE_API="https://api.github.com/repos/WSTxda/ViPERFX_RE/releases/latest"
mod_url=$(curl -s $CURL_AUTH_ARGS "$MODULE_API" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*viper4android_module[^"]*\.zip\)".*/\1/p' | head -n1)
if [ -n "$mod_url" ]; then
  TMPDIR=$(mktemp -d)
  TMPZIP="$TMPDIR/viper.zip"
  DOWNLOAD_FILE "$mod_url" "$TMPZIP" || true
  EXTDIR=$(mktemp -d)
  unzip -j "$TMPZIP" "common/files/libv4a_re_armeabi-v7a.so" -d "$EXTDIR" >/dev/null 2>&1 || true
  unzip -j "$TMPZIP" "common/files/libv4a_re_arm64-v8a.so" -d "$EXTDIR" >/dev/null 2>&1 || true
  if [ -f "$EXTDIR/libv4a_re_armeabi-v7a.so" ]; then
    mkdir -p "$MODPATH/vendor/lib/soundfx"
    cp -f "$EXTDIR/libv4a_re_armeabi-v7a.so" "$MODPATH/vendor/lib/soundfx/libv4a_re.so"
    ADD_TO_WORK_DIR "$MODPATH" "vendor" "lib/soundfx/libv4a_re.so" 0 0 644 "u:object_r:vendor_file:s0"
  fi
  if [ -f "$EXTDIR/libv4a_re_arm64-v8a.so" ]; then
    mkdir -p "$MODPATH/vendor/lib64/soundfx"
    cp -f "$EXTDIR/libv4a_re_arm64-v8a.so" "$MODPATH/vendor/lib64/soundfx/libv4a_re.so"
    ADD_TO_WORK_DIR "$MODPATH" "vendor" "lib64/soundfx/libv4a_re.so" 0 0 644 "u:object_r:vendor_file:s0"
  fi
  rm -rf "$TMPDIR" "$EXTDIR"
fi

CFGS="$(find "$WORK_DIR/system" "$WORK_DIR/vendor" -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
for f in ${CFGS}; do
    case "$f" in
        *.conf)
            sed -i "/v4a_standard_re {/,/}/d" "$f"
            sed -i "/v4a_re {/,/}/d" "$f"
            sed -i "s/^effects {/effects {\n  v4a_standard_re {\n    library v4a_re\n    uuid 90380da3-8536-4744-a6a3-5731970e640f\n  }/g" "$f"
            sed -i "s/^libraries {/libraries {\n  v4a_re {\n    path \/vendor\/lib\/soundfx\/libv4a_re.so\n  }/g" "$f"
            ;;
        *.xml)
            sed -i "/v4a_standard_re/d" "$f"
            sed -i "/v4a_re/d" "$f"
            sed -i "/<libraries>/ a\        <library name=\"v4a_re\" path=\"libv4a_re.so\"\/>" "$f"
            sed -i "/<effects>/ a\        <effect name=\"v4a_standard_re\" library=\"v4a_re\" uuid=\"90380da3-8536-4744-a6a3-5731970e640f\"\/>" "$f"
            ;;
    esac
done

GITHUB_API="https://api.github.com/repos/WSTxda/ViperFX-RE-Releases/releases/latest"
V4A_APK=$(curl -s $CURL_AUTH_ARGS "$GITHUB_API" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p' | grep -i 'viper.*\.apk' | head -n1)

APK_PATH="system/preload/Viper4AndroidFX-RE/com.wstxda.viper4android==/base.apk"
DOWNLOAD_FILE "$V4A_APK" "$WORK_DIR/system/$APK_PATH"

sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system"
sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"

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

LOG_STEP_OUT

unset CURL_AUTH_ARGS MODULE_API mod_url TMPDIR TMPZIP EXTDIR CFGS GITHUB_API V4A_APK APK_PATH FILE