DELETE_FROM_WORK_DIR "system" "system/lib64/libenn_wrapper_system.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libeden_wrapper_system.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsnap_aidl.snap.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
