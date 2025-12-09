LOG_STEP_IN "- Replacing camera blobs"
BLOBS_LIST="
system/lib64/libenn_wrapper_system.so
system/lib64/libpic_best.arcsoft.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libdualcam_refocus_gallery_54.so
system/lib64/libdualcam_refocus_gallery_50.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libface_recognition.arcsoft.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

BLOBS_LIST="
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libMultiFrameProcessing10.camera.samsung.so
system/lib64/libMultiFrameProcessing20.camera.samsung.so
system/lib64/libMultiFrameProcessing20Day.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/vendor.samsung_slsi.hardware.iva@1.0.so
system/lib64/vendor.samsung_slsi.hardware.MultiFrameProcessing20@1.0.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

LOG_STEP_OUT

LOG_STEP_IN "- Removing HDR10+ check"
ADD_TO_WORK_DIR "pa3qzcx" "system" "system/lib64/libstagefright.so" 0 0 644 "u:object_r:system_lib_file:s0"
HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" "010140f9cf390594a0500034" "010140f91f2003d51f2003d5"

BLOBS_LIST="
system/lib64/libeden_wrapper_system.so
system/lib64/libsnap_aidl.snap.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3sxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done
LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 (p3sxxx) SWISP models"
DELETE_FROM_WORK_DIR "vendor" "saiv/swisp_1.0"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "saiv/swisp_1.0"

BLOBS_LIST="
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3sxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done
LOG_STEP_OUT

LOG_STEP_IN "- Adding A26 (a26xxx) Polarr SDK blobs"
ADD_TO_WORK_DIR "a26xxx" "system" "system/etc/public.libraries-polarr.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a26xxx" "system" "system/lib64/libBestComposition.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a26xxx" "system" "system/lib64/libFeature.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a26xxx" "system" "system/lib64/libTracking.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Cleaning SamsungCamera OAT"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/oat"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/SamsungCamera.apk.prof"
DELETE_FROM_WORK_DIR "system" "system/app/FilterProvider/oat"
LOG_STEP_OUT

LOG_STEP_IN "- Fixing AI Photo Editor"
cp -a --preserve=all \
    "$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json" \
    "$WORK_DIR/system/system/cameradata/portrait_data/nexus_bokeh_feature.json"
SET_METADATA "system" "system/cameradata/portrait_data/nexus_bokeh_feature.json" 0 0 644 "u:object_r:system_file:s0"
sed -i "s/MODEL_TYPE_INSTANCE_CAPTURE/MODEL_TYPE_OBJ_INSTANCE_CAPTURE/g" \
    "$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json"
sed -i \
    's/system\/cameradata\/portrait_data\/single_bokeh_feature.json/system\/cameradata\/portrait_data\/nexus_bokeh_feature.json\x00/g' \
    "$WORK_DIR/system/system/lib64/libPortraitSolution.camera.samsung.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 (p3sxxx) SingleTake models"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "etc/singletake"

BLOBS_LIST="
system/priv-app/SingleTakeService/SingleTakeService.apk
system/cameradata/singletake/service-feature.xml
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3sxxx" "system" "$blob" 0 0 644 "u:object_r:system_file:s0" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

LOG "- Decompiling SamsungCamera" # To fool build system into recompiling + signing it at the end
DECODE_APK "system" "system/priv-app/SamsungCamera/SamsungCamera.apk"

if [[ "$TARGET_CODENAME" == "beyond2lte" ]]; then
    LOG "- Adding stock cutout assets"
    cp -a "$MODPATH/assets/lottie_camera_punchcut_timer_b2.json" "$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk/res/raw/lottie_camera_punchcut_timer_b0.json"
    cp -a "$MODPATH/assets/face_unlocking_cutout_ic_b2.json" "$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk/res/raw/face_unlocking_cutout_ic_b0.json"
fi

if [[ "$TARGET_CODENAME" == "beyondx" ]]; then
    LOG "- Adding stock cutout assets"
    cp -a "$MODPATH/assets/lottie_camera_punchcut_timer_bx.json" "$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk/res/raw/lottie_camera_punchcut_timer_b0.json"
    cp -a "$MODPATH/assets/face_unlocking_cutout_ic_bx.json" "$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk/res/raw/face_unlocking_cutout_ic_b0.json"
fi

LOG_STEP_OUT
