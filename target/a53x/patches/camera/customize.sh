# Add 360 lite libs
DELETE_FROM_WORK_DIR "system" "system/lib64/libdualcam_portraitlighting_gallery_360.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libdualcam_portraitlighting_gallery_360_lite.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add camera libs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFacialStickerEngine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFood.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libFood.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFoodDetector.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libFoodDetector.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfacialrestoration.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libimage_enhancement.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/liblow_light_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsecimaging_pdk.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"

LOG_STEP_IN "- Replacing HWUI"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT
