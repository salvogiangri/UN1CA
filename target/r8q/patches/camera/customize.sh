SKIPUNZIP=1

# [
ADD_TO_WORK_DIR()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    mkdir -p "$WORK_DIR/$(dirname "$FILE_PATH")"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$FILE_PATH" "$WORK_DIR/$FILE_PATH"

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".camera.samsung.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
        fi
        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".arcsoft.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt"
        fi
        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".media.samsung.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-media.samsung.txt"
        fi

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if ! grep -q "Camera End" "$WORK_DIR/vendor/ueventd.rc"; then
    echo "" >> "$WORK_DIR/vendor/ueventd.rc"
    cat "$SRC_DIR/target/r8q/patches/camera/ueventd" >> "$WORK_DIR/vendor/ueventd.rc"
fi

BLOBS_LIST="
system/lib64/libAEBHDR_wrapper.camera.samsung.so
system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so
system/lib64/libBestPhoto.camera.samsung.so
system/lib64/libDocDeblur.camera.samsung.so
system/lib64/libDocDeblur.enhanceX.samsung.so
system/lib64/libDocObjectRemoval.camera.samsung.so
system/lib64/libDocObjectRemoval.enhanceX.samsung.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libMPISingleRGB40.camera.samsung.so
system/lib64/libMPISingleRGB40Tuning.camera.samsung.so
system/lib64/libRelighting_API.camera.samsung.so
system/lib64/libWideDistortionCorrection.camera.samsung.so
system/lib64/libacz_hhdr.arcsoft.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libaiclearzoom_raw.arcsoft.so
system/lib64/libaiclearzoomraw_wrapper_v1.camera.samsung.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libarcsoft_single_cam_glasses_seg.so
system/lib64/libdualcam_refocus_image.so
system/lib64/libhigh_dynamic_range_bokeh.so
system/lib64/libhybridHDR_wrapper.camera.samsung.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/$blob"
done

echo "Add stock camera libs"
BLOBS_LIST="
system/etc/public.libraries-arcsoft.txt
system/etc/public.libraries-camera.samsung.txt
system/lib64/libFaceRestoration.camera.samsung.so
system/lib64/libFacialStickerEngine.arcsoft.so
system/lib64/libImageCropper.camera.samsung.so
system/lib64/libImageTagger.camera.samsung.so
system/lib64/libMyFilter.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libPortraitDistortionCorrection.arcsoft.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libface_landmark.arcsoft.so
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/libhumantracking_util.camera.samsung.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libhumantracking.arcsoft.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libsecuresnap_aidl.snap.samsung.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/vendor.samsung.hardware.snap-V1-ndk.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done

echo "Add camera configs"
rm -f "$WORK_DIR/system/system/cameradata/camera-feature.xml"
rm -f "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
cp "$SRC_DIR/target/r8q/patches/camera/system/cameradata/camera-feature.xml" "$WORK_DIR/system/system/cameradata"
cp "$SRC_DIR/target/r8q/patches/camera/system/etc/public.libraries-camera.samsung.txt" "$WORK_DIR/system/system/etc"

echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"
