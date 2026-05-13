{
    echo
    cat "$MODPATH/ueventd"
} >> "$WORK_DIR/vendor/ueventd.rc"

# Fix system camera libs
BLOBS_LIST="
system/lib/FrcMcWrapper.so
system/lib/libFrucPSVTLib.so
system/lib/libSemanticMap_v1.camera.samsung.so
system/lib/libSlowShutter-core.so
system/lib/libaifrc.aidl.quram.so
system/lib/libaifrcInterface.camera.samsung.so
system/lib/libmcaimegpu.samsung.so
system/lib/vendor.samsung.hardware.frcmc-V1-ndk.so
system/lib64/FrcMcWrapper.so
system/lib64/libAEBHDR_wrapper.camera.samsung.so
system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so
system/lib64/libBestPhoto.camera.samsung.so
system/lib64/libDocDeblur.camera.samsung.so
system/lib64/libDocObjectRemoval.camera.samsung.so
system/lib64/libDocObjectRemoval.enhanceX.samsung.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libFaceRecognition.arcsoft.so
system/lib64/libFrucPSVTLib.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/libMPISingleRGB40.camera.samsung.so
system/lib64/libMPISingleRGB40Tuning.camera.samsung.so
system/lib64/libPetClustering.camera.samsung.so
system/lib64/libRelighting_API.camera.samsung.so
system/lib64/libSemanticMap_v1.camera.samsung.so
system/lib64/libSlowShutter-core.so
system/lib64/libacz_hhdr.arcsoft.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libaiclearzoom_raw.arcsoft.so
system/lib64/libaiclearzoomraw_wrapper_v1.camera.samsung.so
system/lib64/libaifrc.aidl.quram.so
system/lib64/libaifrcInterface.camera.samsung.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libarcsoft_single_cam_glasses_seg.so
system/lib64/libdualcam_refocus_image.so
system/lib64/libdvs.camera.samsung.so
system/lib64/libfrtracking_engine.arcsoft.so
system/lib64/libhigh_dynamic_range_bokeh.so
system/lib64/libhybridHDR_wrapper.camera.samsung.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libmcaimegpu.samsung.so
system/lib64/libscalenetpkg.so
system/lib64/libstartrail.camera.samsung.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libtensorflowLite2_11_0_dynamic_camera.so
system/lib64/vendor.samsung.hardware.frcmc-V1-ndk.so
"
for i in $BLOBS_LIST; do
    DELETE_FROM_WORK_DIR "system" "$i"
done

LOG_STEP_IN "- Adding stock camera libs"
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
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libPortraitDistortionCorrection.arcsoft.so
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libUltraWideDistortionCorrection.camera.samsung.so
system/lib64/libWideDistortionCorrection.camera.samsung.so
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libhumantracking_util.camera.samsung.so
system/lib64/libhumantracking.arcsoft.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libtensorflowLite.dynamic_viewing.camera.samsung.so
system/lib64/libtensorflowlite_jni_r2.6.so
"
for i in $BLOBS_LIST; do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$i" 0 0 644 "u:object_r:system_lib_file:s0"
done
LOG_STEP_OUT

LOG_STEP_IN "- Fixing Studio Video Editor"
ADD_TO_WORK_DIR "a36xqnaxx" "system" "system/lib64/libMyFilter.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a36xqnaxx" "system" "system/lib64/libtflite2.myfilters.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Fixing MIDAS, AI and camera"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libSlowShutter_jni.media.samsung.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/lib_nativeJni.dk.samsung.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libmidas_DNNInterface.camera.samsung.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libmidas_core.camera.samsung.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libsamsung_videoengine_9_0.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libtensorflowLite.camera.samsung.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libtensorflowlite_inference_api.camera.samsung.so"
LOG_STEP_OUT

unset BLOBS_LIST
