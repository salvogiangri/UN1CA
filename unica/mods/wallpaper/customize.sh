if $DEBUG; then
    LOG "\033[0;33m! Debug build detected. Skipping\033[0m"
    return 0
fi

# [
COMPRESS_WEBP()
{
    local FILE="$1"
    local FILE_PATH
    local FILE_NAME
    local RES="2400"
    local CMD

    FILE_PATH="$(dirname "$FILE")"
    FILE_NAME="$(basename "$FILE")"

    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        if [ "$TARGET_PRODUCT_SHIPPING_API_LEVEL" -gt "30" ] && \
                [ "$TARGET_PRODUCT_SHIPPING_API_LEVEL" -lt "34" ]; then
            RES="3088"
        else
            RES="3120"
        fi
    fi

    LOG "- Compressing $FILE_NAME"

    CMD="cwebp"
    CMD+=" -q 100"
    CMD+=" -resize $RES $RES"
    CMD+=" \"$FILE_PATH/$FILE_NAME\""
    CMD+=" -o \"$FILE_PATH/temp.webp\""

    EVAL "$CMD" || return 1
    EVAL "mv -f \"$FILE_PATH/temp.webp\" \"$FILE_PATH/$FILE_NAME\"" || return 1
}

ENCODE_MP4()
{
    local FILE="$1"
    local FILE_PATH
    local FILE_NAME
    local RES="-1:2400"
    local CMD

    FILE_PATH="$(dirname "$FILE")"
    FILE_NAME="$(basename "$FILE")"

    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        RES="1440:-1"
    fi

    LOG "- Encoding $FILE_NAME"

    CMD="ffmpeg"
    CMD+=" -i \"$FILE_PATH/$FILE_NAME\""
    CMD+=" -c:v libx264 -c:a copy"
    CMD+=" -pix_fmt yuv420p -crf 18 -g 1"
    CMD+=" -preset veryslow -tune zerolatency"
    CMD+=" -movflags use_metadata_tags -map_metadata 0"
    CMD+=" -vf \"fps=60,scale=$RES,setsar=1:1\""
    CMD+=" -video_track_timescale 360000 -movie_timescale 90000"
    CMD+=" \"$FILE_PATH/temp.mp4\""

    EVAL "$CMD" || return 1
    EVAL "mv -f \"$FILE_PATH/temp.mp4\" \"$FILE_PATH/$FILE_NAME\"" || return 1
}
# ]

ADD_TO_WORK_DIR "pa2qxxx" "system" \
    "system/priv-app/wallpaper-res/wallpaper-res.apk" 0 0 644 "u:object_r:system_file:s0"
DECODE_APK "system" "system/priv-app/wallpaper-res/wallpaper-res.apk"
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/drawable-nodpi/dex_wallpaper_"*.webp; do
    COMPRESS_WEBP "$f"
done
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/drawable-nodpi/wallpaper_"*.webp; do
    COMPRESS_WEBP "$f"
done
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/raw/video_"*.mp4; do
    ENCODE_MP4 "$f"
done
APPLY_PATCH "system" "system/priv-app/SpriteWallpaper/SpriteWallpaper.apk" \
    "$MODPATH/SpriteWallpaper.apk/0001-Force-Paradigm-wallpapers-motion-animator.patch"
APPLY_PATCH "system" "system/priv-app/SpriteWallpaper/SpriteWallpaper.apk" \
    "$MODPATH/SpriteWallpaper.apk/0002-Adjust-motion-animator-for-60fps-video-files.patch"
APPLY_PATCH "system" "system/priv-app/wallpaper-res/wallpaper-res.apk" \
    "$MODPATH/wallpaper-res.apk/0001-Adjust-metadata-for-60fps-video-files.patch"

unset -f ENCODE_MP4 COMPRESS_WEBP
