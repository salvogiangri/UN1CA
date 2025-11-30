# Add ImageTagger lib
LOG_STEP_IN "- Replacing ImageTagger Lib"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libImageTagger.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

# Add camera libs
LOG_STEP_IN "- Replacing Camera Libs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libacz_hhdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libae_bracket_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range_bokeh.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking_util.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsecimaging_pdk.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libveengine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaiclearzoom_raw.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaiclearzoomraw_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolution_raw.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libDocObjectRemoval.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libDocDeblur.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libDocObjectRemoval.enhanceX.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libDLInterface_aidl.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

# Upgrade midas blobs
LOG_STEP_IN "- Replacing Midas blobs"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/midas" 0 2000 755 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

# Upgrade singletake blobs
LOG_STEP_IN "- Replacing SingleTake blobs"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/singletake" 0 2000 755 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Stock Camera"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/SamsungCamera.apk"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SamsungCamera/SamsungCamera.apk.prof"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/SamsungCamera/SamsungCamera.apk.prof" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Patching /vendor/etc/ueventd.rc"
EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/etc/ueventd.rc\""
LOG_STEP_OUT
