# [
RESIZE_APK()
{
    local WEBP_RES="2400"
    local MP4_RES="1080:-1"

    if $TARGET_HAS_QHD_DISPLAY; then
        if [[ "$TARGET_PRODUCT_FIRST_API_LEVEL" -le 30 ]]; then
            WEBP_RES="3200"
        else
            WEBP_RES="3088"
        fi
        MP4_RES="1440:-1"
    fi

    echo "Resize wallpaper-res.apk"
    DECODE_APK "system" "system/priv-app/wallpaper-res/wallpaper-res.apk"
    for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/drawable-nodpi/Wallpaper_"*.webp
    do
        cwebp -q 100 -resize $WEBP_RES $WEBP_RES "$f" -o "$(dirname "$f")/temp.webp" &> /dev/null
        mv -f "$(dirname "$f")/temp.webp" "$f"
    done
    for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/raw/"*.mp4
    do
        ffmpeg -i "$f" -c:v libx265 -tag:v hvc1 -c:a copy \
            -crf 18 -movflags use_metadata_tags -map_metadata 0 \
            -vf "scale=$MP4_RES,setsar=1:1" -video_track_timescale 60000 \
            "$(dirname "$f")/temp.mp4" &> /dev/null
        mv -f "$(dirname "$f")/temp.mp4" "$f"
    done
}
# ]

ADD_TO_WORK_DIR "e1qzcx" "system" \
    "system/priv-app/wallpaper-res/wallpaper-res.apk" 0 0 644 "u:object_r:system_file:s0"
RESIZE_APK
