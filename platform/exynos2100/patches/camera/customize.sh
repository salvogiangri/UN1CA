LOG_STEP_IN "- Adding stock camera libs"
BLOBS_LIST="
system/lib64/libenn_wrapper_system.so
system/lib64/libdualcam_portraitlighting_gallery_360.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob"
done

BLOBS_LIST="
system/lib64/libdualcam_portraitlighting_gallery_360_lite.so
system/lib64/libdualcam_refocus_gallery_50.so
system/lib64/libFood.camera.samsung.so
system/lib64/libFoodDetector.camera.samsung.so
system/lib64/libeden_wrapper_system.so
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so
system/lib64/libhumantracking.arcsoft.so
system/lib64/libImageTagger.camera.samsung.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libsecuresnap_aidl.snap.samsung.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so
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
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done
LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 FE (r9sxxx) MIDAS blobs"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
DELETE_FROM_WORK_DIR "vendor" "etc/VslMesDetector"
ADD_TO_WORK_DIR "r9sxxx" "vendor" "etc/midas"
ADD_TO_WORK_DIR "r9sxxx" "vendor" "etc/VslMesDetector"
LOG_STEP_OUT

LOG "- Fixing MIDAS model detection"
sed -i "s/r9s/r0s/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"

LOG_STEP_IN "- Adding S21 FE (r9sxxx) Photo Remaster Service"
DELETE_FROM_WORK_DIR "system" "system/priv-app/PhotoRemasterService/oat"
ADD_TO_WORK_DIR "r9sxxx" "system" "system/priv-app/PhotoRemasterService/PhotoRemasterService.apk"
LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 FE (r9sxxx) MIDAS libs"
ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib64/libmidas_core.camera.samsung.so"
ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib64/libmidas_DNNInterface.camera.samsung.so"
LOG_STEP_OUT