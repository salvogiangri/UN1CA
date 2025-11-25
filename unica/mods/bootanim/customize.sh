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
    
    case 1 in
        $(echo "$RATIO >= 2.14 && $RATIO <= 2.17" | bc -l))
            LOG "- Adding 2024 boot animation blobs (1080x2340)"
            cp -a "$MODPATH/1080x2340/"* "$WORK_DIR/system/system/media"
            ;;
        $(echo "$RATIO >= 2.20 && $RATIO <= 2.24" | bc -l))
            LOG "- Adding 2024 boot animation blobs (1080x2400)"
            cp -a "$MODPATH/1080x2400/"* "$WORK_DIR/system/system/media"
            ;;
        *)
            LOGW "- Unknown boot animation resolution for \"$TARGET_CODENAME\". Skipping"
            ;;
    esac
else
    LOGW "- Could not find BACK_CAMERA_RESOLUTION_FULL_RATIO"
fi

unset XML_FILE WIDTH HEIGHT RATIO
