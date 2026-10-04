LOG_STEP_IN "- Adding FM Radio blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfmradio_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vendor.qti.hardware.fm-V1-ndk.so" 0 0 755 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/fm_helium.so" 0 0 755 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libfm-hci.so" 0 0 755 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.fm@1.0.so" 0 0 755 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/android.hardware.bluetooth.audio-V3-ndk.so" 0 0 755 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/android.hardware.audio.common-V2-ndk.so" 0 0 755 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/android.media.audio.common.types-V2-ndk.so" 0 0 755 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Removing Google Hotword Enrollment blobs"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
LOG_STEP_OUT
