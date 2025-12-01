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

GET_HW_ACCEL()
{
    local HW_ACCEL=""
    local GPU_VENDOR=""
    local HAS_H264_ENC=false
    local HAS_H265_DEC=false

    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        GPU_VENDOR="nvidia"
    elif lspci 2>/dev/null | grep -qi "VGA.*AMD\|Display.*AMD"; then
        GPU_VENDOR="amd"
    elif lspci 2>/dev/null | grep -qi "VGA.*Intel\|Display.*Intel"; then
        GPU_VENDOR="intel"
    fi

    if [ "$GPU_VENDOR" = "nvidia" ]; then
        if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_nvenc"; then
            HAS_H264_ENC=true
        fi
        if ffmpeg -hide_banner -decoders 2>/dev/null | grep -q "hevc_cuvid"; then
            HAS_H265_DEC=true
        fi
        if $HAS_H264_ENC && $HAS_H265_DEC; then
            HW_ACCEL="nvidia"
        fi
    elif [ "$GPU_VENDOR" = "amd" ] || [ "$GPU_VENDOR" = "intel" ]; then
        if ffmpeg -hwaccels 2>/dev/null | grep -q "vaapi" && [ -e /dev/dri/renderD128 ]; then
            if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_vaapi"; then
                HAS_H264_ENC=true
            fi
            if ffmpeg -hide_banner -decoders 2>/dev/null | grep -q "hevc_vaapi"; then
                HAS_H265_DEC=true
            fi
            if $HAS_H264_ENC && $HAS_H265_DEC; then
                HW_ACCEL="vaapi"
            fi
        fi
    fi

    echo "$HW_ACCEL"
}

ENCODE_MP4()
{
    local FILE="$1"
    local FILE_PATH
    local FILE_NAME
    local RES_W="-1"
    local RES_H="2400"
    local CMD
    local HW_ACCEL

    FILE_PATH="$(dirname "$FILE")"
    FILE_NAME="$(basename "$FILE")"
    HW_ACCEL="$(GET_HW_ACCEL)"

    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        RES_W="1440"
        RES_H="-1"
    fi

    LOG "- Encoding $FILE_NAME"

    CMD="ffmpeg -y"

    if [ "$HW_ACCEL" = "nvidia" ]; then
        CMD+=" -hwaccel cuda -hwaccel_output_format cuda -c:v hevc_cuvid"
        CMD+=" -i \"$FILE_PATH/$FILE_NAME\""
        CMD+=" -vf \"fps=60,scale_cuda=w=${RES_W}:h=${RES_H}:format=yuv420p,hwdownload,format=yuv420p,setsar=1:1\""
        CMD+=" -c:v h264_nvenc -preset p7 -cq 18 -g 60 -bf 0"
    elif [ "$HW_ACCEL" = "vaapi" ]; then
        CMD+=" -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi"
        CMD+=" -i \"$FILE_PATH/$FILE_NAME\""
        CMD+=" -vf \"fps=60,scale_vaapi=w=${RES_W}:h=${RES_H}:format=nv12,setsar=1:1\""
        CMD+=" -c:v h264_vaapi -qp 18 -g 60 -bf 0"
    else
        CMD+=" -i \"$FILE_PATH/$FILE_NAME\""
        CMD+=" -vf \"fps=60,scale=${RES_W}:${RES_H},setsar=1:1\""
        CMD+=" -c:v libx264 -pix_fmt yuv420p -crf 18 -g 60"
        CMD+=" -preset veryslow -tune zerolatency"
    fi

    CMD+=" -c:a copy"
    CMD+=" -movflags use_metadata_tags -map_metadata 0"
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
APPLY_PATCH "system" "system/priv-app/wallpaper-res/wallpaper-res.apk" \
    "$MODPATH/wallpaper-res.apk/0001-Adjust-metadata-for-60fps-video-files.patch"

unset -f ENCODE_MP4 COMPRESS_WEBP GET_HW_ACCEL
