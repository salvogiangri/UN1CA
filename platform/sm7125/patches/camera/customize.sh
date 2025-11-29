LOG_STEP_IN "- Adding ImageTagger lib from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libImageTagger.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Polarr libs from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/etc/public.libraries-polarr.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libBestComposition.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libFeature.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libPolarrSnap.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libTracking.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libYuv.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding camera libs from stock"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSceneDetector_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/liblow_light_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking_util.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsecimaging_pdk.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libveengine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT
