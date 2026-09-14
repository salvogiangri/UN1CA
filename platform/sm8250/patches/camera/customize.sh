# Fix system camera libs
BLOBS_LIST="
system/lib64/libAEBHDR_wrapper.camera.samsung.so
system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so
system/lib64/libBestPhoto.camera.samsung.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libFaceRecognition.arcsoft.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/libMPISingleRGB40.camera.samsung.so
system/lib64/libMPISingleRGB40Tuning.camera.samsung.so
system/lib64/libPetClustering.camera.samsung.so
system/lib64/libRelighting_API.camera.samsung.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libarcsoft_single_cam_glasses_seg.so
system/lib64/libdualcam_refocus_image.so
system/lib64/libdvs.camera.samsung.so
system/lib64/libfrtracking_engine.arcsoft.so
system/lib64/libhigh_dynamic_range_bokeh.so
system/lib64/libhybridHDR_wrapper.camera.samsung.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libscalenetpkg.so
system/lib64/libstartrail.camera.samsung.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libtensorflowLite2_11_0_dynamic_camera.so
system/lib64/libdualcam_refocus_gallery_54.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob"
done

echo "Add stock camera libs"
BLOBS_LIST="
system/etc/public.libraries-arcsoft.txt
system/etc/public.libraries-camera.samsung.txt
system/lib64/libAiSolution_wrapper_v1.camera.samsung.so
system/lib64/libBright_core.camera.samsung.so
system/lib64/libFacePreProcessing.camera.samsung.so
system/lib64/libFaceRestoration.camera.samsung.so
system/lib64/libFace_Landmark_API.camera.samsung.so
system/lib64/libFace_Landmark_Engine.camera.samsung.so
system/lib64/libHprFace_GAE_api.camera.samsung.so
system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so
system/lib64/libHpr_RecGAE_cvFeature_v1.0.camera.samsung.so
system/lib64/libHpr_TaskFaceClustering_hierarchical_v1.0.camera.samsung.so
system/lib64/libImageCropper.camera.samsung.so
system/lib64/libImageTagger.camera.samsung.so
system/lib64/libPortraitDistortionCorrection.arcsoft.so
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libUltraWideDistortionCorrection.camera.samsung.so
system/lib64/libWideDistortionCorrection.camera.samsung.so
system/lib64/libhumantracking_util.camera.samsung.so
system/lib64/libhumantracking.arcsoft.so
system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so
system/lib64/libtensorflowLite.dynamic_viewing.camera.samsung.so
system/lib64/libtensorflowlite_jni_r2.6.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

BLOBS_LIST="
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3qxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done

# HDR fix
LOG_STEP_IN "- Adding hdr-fix"
ADD_TO_WORK_DIR "r9qxxx" "system" \
    "lib/libstagefright.so" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

# Pro mode EV Fix
LOG_STEP_IN "- Adding camera PRO mode EV-fix"
ADD_TO_WORK_DIR "r9qxxx" "vendor" \
    "lib64/X12QS_libTsAe.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT
