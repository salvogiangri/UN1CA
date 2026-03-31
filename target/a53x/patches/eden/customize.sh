DELETE_FROM_WORK_DIR "system" "system/lib/vendor.samsung_slsi.hardware.enn_aux@1.0.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libenn_wrapper_system.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung_slsi.hardware.enn_aux@1.0.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libeden_wrapper_system.so" 0 0 644 "u:object_r:system_lib_file:s0"
