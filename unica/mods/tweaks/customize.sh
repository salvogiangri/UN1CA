SKIPUNZIP=1

echo "Resize wallpaper-res.apk"
if [ ! -d "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk" ]; then
    bash "$SRC_DIR/scripts/apktool.sh" d "system/priv-app/wallpaper-res/wallpaper-res.apk"
fi
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/drawable-nodpi/Wallpaper_"*.webp
do
    cwebp -q 100 -resize 2400 2400 "$f" -o "$(dirname "$f")/temp.webp" &> /dev/null
    mv -f "$(dirname "$f")/temp.webp" "$f"
done
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/raw/"*.mp4
do
    ffmpeg -i "$f" -c:v libx265 -tag:v hvc1 -c:a copy \
        -crf 18 -movflags use_metadata_tags -map_metadata 0 \
        -vf "scale=-1:2400,setsar=1:1" -video_track_timescale 60000 \
        "$(dirname "$f")/temp.mp4" &> /dev/null
    mv -f "$(dirname "$f")/temp.mp4" "$f"
done
