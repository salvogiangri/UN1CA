CAMERA_LIBS="
system/lib64/libBST3DDNS.so
system/lib64/libBstStick2D.so
system/lib64/libBSTAiScene.so
system/lib64/libbst_mosaic.so
system/lib64/libBSTBeauty.so
system/lib64/libglext.so
system/lib64/libBSTDocShadowRemove.so
system/lib64/libjniBst3ddns.so
system/lib64/libBSTDualCamBokeh.so
system/lib64/libjniBstAiDoc.so
system/lib64/libBSTFaceDetction.so
system/lib64/libjniBstAiScene.so
system/lib64/libBSTFilter.so
system/lib64/libjniBstBeauty.so
system/lib64/libBSTFoodMode.so
system/lib64/libjniBstDualBokeh.so
system/lib64/libBSTHdrDynamicJni.so
system/lib64/libjniBstFilter.so
system/lib64/libBSTMultiExpoGainHDR.so
system/lib64/libjniBstFoodMode.so
system/lib64/libBSTSingleAIBokeh.so
system/lib64/libjniBstHandDetect.so
system/lib64/libBSTSingleAIDoc.so
system/lib64/libjniBstPanorama.so
system/lib64/libBSTSpecialEffect.so
system/lib64/libjniBstSingleBokeh.so
system/lib64/libBSTYuvNight.so
system/lib64/libjniBstSticker.so
system/lib64/libBstHD.so
system/lib64/libjniBstYuvNight.so
"

LOG_STEP_IN "- Adding JDM camera libs"
for f in $CAMERA_LIBS; do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$f" 0 0 644 "u:object_r:system_lib_file:s0"
done
LOG_STEP_OUT

LOG_STEP_IN "- Adding JDM cameraserver"
ADD_TO_WORK_DIR "gta9pxxx" "system" "system/bin/cameraserver" 0 2000 755 "u:object_r:cameraserver_exec:s0"
LOG_STEP_OUT

unset CAMERA_LIBS