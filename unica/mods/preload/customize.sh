SKIPUNZIP=1

# [
GET_GALAXY_STORE_DOWNLOAD_URL()
{
    echo "$(curl -L -s "https://vas.samsungapps.com/stub/stubDownload.as?appId=$1&deviceId=SM-S911B&mcc=262&mnc=01&csc=EUX&sdkVer=34&extuk=0191d6627f38685f&pd=0" \
        | grep 'downloadURI' | cut -d ">" -f 2 | sed -e 's/<!\[CDATA\[//g; s/\]\]//g')"
}

DOWNLOAD_APK()
{
    local URL="$1"
    local APK_PATH="system/preload/$2"

    echo "Adding $(basename "$APK_PATH") to preload apps"
    mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
    curl -L -s -o "$WORK_DIR/system/$APK_PATH" -z "$WORK_DIR/system/$APK_PATH" "$URL"
}
# ]

# Patched GoodLock Manager @corsicanu
# https://github.com/corsicanu/goodlock_dump
DOWNLOAD_APK "https://github.com/corsicanu/goodlock_dump/raw/main/GoodLock_patched.apk" \
    "GoodLock/GoodLock.apk"



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
