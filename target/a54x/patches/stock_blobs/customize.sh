LOG_STEP_IN "- Replacing Hotword"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM4" 0 0 755 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM4" 0 0 755 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Audio blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundAlive_play_plus_ver500.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Add keymite 2.0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/android.hardware.security.keymint-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vendor.samsung.hardware.keymint-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/android.hardware.security.keymint-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/vendor.samsung.hardware.keymint-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT



