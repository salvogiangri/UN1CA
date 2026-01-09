echo "Add stock camera libs"
BLOBS_LIST="
system/etc/public.libraries-arcsoft.txt
system/etc/public.libraries-camera.samsung.txt
system/lib/libSlowShutter_jni.media.samsung.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libFace_Landmark_Engine.camera.samsung.so
system/lib64/libHREnhancementAPI.camera.samsung.so
system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so
system/lib64/libImageCropper.camera.samsung.so
system/lib64/libImageTagger.camera.samsung.so
system/lib64/libLocalTM_pcc.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libPortraitDistortionCorrection.arcsoft.so
system/lib64/libSlowShutter_jni.media.samsung.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libarcsoft_superresolution_bokeh.so
system/lib64/libdualcam_refocus_image.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libhighres_enhancement.arcsoft.so
system/lib64/libhumantracking.arcsoft.so
system/lib64/libhybridHDR_wrapper.camera.samsung.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so
system/lib64/libsamsung_videoengine_9_0.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libuwsuperresolution.arcsoft.so
system/lib64/libuwsuperresolution_wrapper_v1.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done

echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"
