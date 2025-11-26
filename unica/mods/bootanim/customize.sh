XML_FILE="$SRC_DIR/target/$TARGET_CODENAME/camera/camera-feature.xml"

read -r WIDTH HEIGHT RATIO <<< "$(awk '
    /name="BACK_CAMERA_RESOLUTION_FULL_RATIO"/ {
        if (match($0, /value="([0-9]+)x([0-9]+)"/, arr)) {
            width = arr[1]
            height = arr[2]
            if (height != 0) {
                ratio = width / height
                printf "%s %s %.2f\n", width, height, ratio
            }
        }
    }
' "$XML_FILE")"

if [[ -n "$RATIO" ]]; then
    LOG "- BACK_CAMERA_RESOLUTION_FULL_RATIO: $WIDTH x $HEIGHT, ratio=$RATIO"
    
    RATIO_2340=2.16 # 2340/1080
    RATIO_2340_DELTA=0.02
    
    RATIO_2400=2.22 # 2400/1080
    RATIO_2400_DELTA=0.02
    
    if [ "$(echo "$RATIO >= $RATIO_2340 - $RATIO_2340_DELTA && $RATIO <= $RATIO_2340 + $RATIO_2340_DELTA" | bc -l)" = "1" ]; then
        LOG "- Adding 2024 boot animation blobs (1080x2340)"
        EVAL "cp -a \"$MODPATH/1080x2340/\"* \"$WORK_DIR/system/system/media\""
    elif [ "$(echo "$RATIO >= $RATIO_2400 - $RATIO_2400_DELTA && $RATIO <= $RATIO_2400 + $RATIO_2400_DELTA" | bc -l)" = "1" ]; then
        LOG "- Adding 2024 boot animation blobs (1080x2400)"
        EVAL "cp -a \"$MODPATH/1080x2400/\"* \"$WORK_DIR/system/system/media\""
    else
        LOGW "- Unknown boot animation resolution for \"$TARGET_CODENAME\". Skipping"
    fi
else
    LOGW "- Could not find BACK_CAMERA_RESOLUTION_FULL_RATIO"
fi

unset XML_FILE WIDTH HEIGHT RATIO RATIO_2340 RATIO_2340_DELTA RATIO_2400 RATIO_2400_DELTA
