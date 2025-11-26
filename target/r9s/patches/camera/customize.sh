LOG_STEP_IN "- Replacing camera blobs"
BLOBS_LIST="
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libdualcam_refocus_gallery_50.so
system/lib64/libdualcam_refocus_gallery_54.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libenn_wrapper_system.so
system/lib64/libface_recognition.arcsoft.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libpic_best.arcsoft.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

BLOBS_LIST="
system/lib64/libDocShadowRemoval.arcsoft.so
system/lib64/libeden_wrapper_system.so
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libObjectDetector_v1.camera.samsung.so
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libSceneDetector_v1.camera.samsung.so
system/lib64/libsecuresnap_aidl.snap.samsung.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libVideoClassifier.camera.samsung.so
"
if [[ "$TARGET_CODENAME" == "p3s" ]]; then
    BLOBS_LIST+="
    system/lib64/libsuperresolution_raw.arcsoft.so
    system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
    system/lib64/libuwsuperresolution.arcsoft.so
    system/lib64/libuwsuperresolution_wrapper_v1.camera.samsung.so
    "
fi
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

ADD_TO_WORK_DIR "p3sxxx" "system" "system/priv-app/SingleTakeService/SingleTakeService.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT
