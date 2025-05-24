DELETE_FROM_WORK_DIR "system" "system/cameradata/portrait_data"
ADD_TO_WORK_DIR "a52qnsxx" "system" "system/cameradata/portrait_data" 0 0 755 "u:object_r:system_file:s0"

if ! grep -q "Camera End" "$WORK_DIR/vendor/ueventd.rc"; then
    echo "" >> "$WORK_DIR/vendor/ueventd.rc"
    cat "$SRC_DIR/target/m51/patches/camera/ueventd" >> "$WORK_DIR/vendor/ueventd.rc"
fi

BLOBS_LIST="
system/lib/FrcMcWrapper.so
system/lib/libFrucPSVTLib.so
system/lib/libSemanticMap_v1.camera.samsung.so
system/lib/libSlowShutter-core.so
system/lib/libaifrc.aidl.quram.so
system/lib/libaifrcInterface.camera.samsung.so
system/lib/libgpuss_wrapper.so
system/lib/libmcaimegpu.samsung.so
system/lib/vendor.samsung.hardware.frcmc-V1-ndk.so
system/lib64/FrcMcWrapper.so
system/lib64/libAEBHDR_wrapper.camera.samsung.so
system/lib64/libAIQSolution_MPI.camera.samsung.so
system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so
system/lib64/libBestPhoto.camera.samsung.so
system/lib64/libDeepDocRectify.camera.samsung.so
system/lib64/libDocDeblur.camera.samsung.so
system/lib64/libDocDeblur.enhanceX.samsung.so
system/lib64/libDocObjectRemoval.camera.samsung.so
system/lib64/libDocObjectRemoval.enhanceX.samsung.so
system/lib64/libDocShadowRemoval.arcsoft.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libFaceRecognition.arcsoft.so
system/lib64/libFrucPSVTLib.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/libLocalTM_pcc.camera.samsung.so
system/lib64/libMPISingleRGB40.camera.samsung.so
system/lib64/libMPISingleRGB40Tuning.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libObjectDetector_v1.camera.samsung.so
system/lib64/libPetClustering.camera.samsung.so
system/lib64/libRelighting_API.camera.samsung.so
system/lib64/libSemanticMap_v1.camera.samsung.so
system/lib64/libSlowShutter-core.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libVideoClassifier.camera.samsung.so
system/lib64/libWideDistortionCorrection.camera.samsung.so
system/lib64/lib_pet_detection.arcsoft.so
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
system/lib64/libfacialrestoration.arcsoft.so
system/lib64/libfrtracking_engine.arcsoft.so
system/lib64/libgpuss_wrapper.so
system/lib64/libhigh_dynamic_range_bokeh.so
system/lib64/libhybridHDR_wrapper.camera.samsung.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libmcaimegpu.samsung.so
system/lib64/libscalenetpkg.so
system/lib64/libstartrail.camera.samsung.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libtensorflowLite2_11_0_dynamic_camera.so
system/lib64/libtflite2.myfilters.camera.samsung.so
system/lib64/vendor.samsung.hardware.frcmc-V1-ndk.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob"
done

echo "Add stock camera libs"
BLOBS_LIST="
system/lib64/libBeauty_v4.camera.samsung.so  
system/lib64/libDLInterface_hidl.camera.samsung.so  
system/lib64/libFacePreProcessing.camera.samsung.so  
system/lib64/libFacePreProcessing_jni.camera.samsung.so  
system/lib64/libFace_Landmark_API.camera.samsung.so  
system/lib64/libFace_Landmark_Engine.camera.samsung.so  
system/lib64/libFacialAttributeDetection.arcsoft.so  
system/lib64/libFacialBasedSelfieCorrection.camera.samsung.so  
system/lib64/libFacialStickerEngine.arcsoft.so  
system/lib64/libFood.camera.samsung.so  
system/lib64/libFoodDetector.camera.samsung.so  
system/lib64/libHprFace_GAE_api.camera.samsung.so  
system/lib64/libHprFace_GAE_jni.camera.samsung.so  
system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so  
system/lib64/libHpr_RecGAE_cvFeature_v1.0.camera.samsung.so  
system/lib64/libHpr_TaskFaceClustering_hierarchical_v1.0.camera.samsung.so  
system/lib64/libImageScreener.camera.samsung.so  
system/lib64/libImageTagger.camera.samsung.so  
system/lib64/libInteractiveSegmentation.camera.samsung.so  
system/lib64/libMattingCore.camera.samsung.so  
system/lib64/libMyFilter.camera.samsung.so  
system/lib64/libMyFilterPlugin.camera.samsung.so  
system/lib64/libOpenCv.camera.samsung.so  
system/lib64/libPortraitDistortionCorrection.arcsoft.so  
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so  
system/lib64/libPortraitSolution.camera.samsung.so  
system/lib64/libSceneDetector_v1.camera.samsung.so  
system/lib64/libSegmentationCore.camera.samsung.so  
system/lib64/libSmartScan.camera.samsung.so  
system/lib64/libStride.camera.samsung.so  
system/lib64/libStrideTensorflowLite.camera.samsung.so  
system/lib64/libUltraWideDistortionCorrection.camera.samsung.so  
system/lib64/libhigh_dynamic_range.arcsoft.so  
system/lib64/libhumantracking.arcsoft.so  
system/lib64/libhumantracking_util.camera.samsung.so  
system/lib64/liblow_light_hdr.arcsoft.so  
system/lib64/libsaiv_HprFace_api.camera.samsung.so  
system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so  
system/lib64/libsmart_cropping.camera.samsung.so  
system/lib64/libsurfaceutil.camera.samsung.so  
system/lib64/libtensorflowLite.camera.samsung.so  
system/lib64/libtensorflowLite.myfilter.camera.samsung.so  
system/lib64/libtensorflowlite_inference_api.camera.samsung.so  
system/lib64/libtensorflowlite_inference_api.myfilter.camera.samsung.so
system/lib64/libdng_sdk.so  
system/lib64/libdynamic_depth.so  
system/lib64/libheif.so  
system/lib64/libheifcapture.so  
system/lib64/libheifcapture_jni.media.samsung.so  
system/lib64/libjpega.camera.samsung.so  
system/lib64/libpiex.so  
system/lib64/libstagefright_bufferqueue_helper.so  
system/lib64/libstagefright_framecapture_utils.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done

echo "Fix AI Photo Editor"
cp -a --preserve=all \
    "$SRC_DIR/prebuilts/samsung/a52qnsxx/system/cameradata/portrait_data/single_bokeh_feature.json" \
    "$WORK_DIR/system/system/cameradata/portrait_data/unica_bokeh_feature.json"
SET_METADATA "system" "system/cameradata/portrait_data/unica_bokeh_feature.json" 0 0 644 "u:object_r:system_file:s0"
sed -i "s/MODEL_TYPE_INSTANCE_CAPTURE/MODEL_TYPE_OBJ_INSTANCE_CAPTURE/g" \
    "$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json"
sed -i \
    's/system\/cameradata\/portrait_data\/single_bokeh_feature.json/system\/cameradata\/portrait_data\/unica_bokeh_feature.json\x00/g' \
    "$WORK_DIR/system/system/lib64/libPortraitSolution.camera.samsung.so"
