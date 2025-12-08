LOG_STEP_IN "- Replacing Hotword"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON/HotwordEnrollmentOKGoogleEx4HEXAGON.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx4HEXAGON/HotwordEnrollmentXGoogleEx4HEXAGON.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Fixing BT audio"
DELETE_FROM_WORK_DIR "system" "system/apex/com.android.bt.apex"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/apex/com.android.bt.apex" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing GameDriver"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-SM8550/GameDriver-SM8550.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock WFD blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/bin/insthk" 0 2000 755 "u:object_r:insthk_exec:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libstagefright_hdcp.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock hwui blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Camera ISP (Image Signal Processor) blobs"
# SwIsp (Software ISP) libraries - required for camera Super Night mode
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# AIQ (Auto Image Quality) Solution libraries - required for camera AI processing
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libAIQSolution_MPI.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT
