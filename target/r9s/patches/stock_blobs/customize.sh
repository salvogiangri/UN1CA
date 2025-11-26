LOG_STEP_IN "- Patching vendor for specific devices"
DELETE_FROM_WORK_DIR "vendor" "lib64/libsec-ril.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "vendor" "lib64/libsec-ril.so" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing MIDAS libraries"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libmidas_core.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libmidas_DNNInterface.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Photo Remaster Service"
DELETE_FROM_WORK_DIR "system" "system/priv-app/PhotoRemasterService/oat"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/PhotoRemasterService/PhotoRemasterService.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Stock Camera Blobs"
DELETE_FROM_WORK_DIR "system" "system/cameradata/camera-feature.xml"
DELETE_FROM_WORK_DIR "system" "system/lib64/libImageTagger.camera.samsung.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libobjectcapture.arcsoft.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libobjectcapture_jni.arcsoft.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libSmartScan.camera.samsung.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/cameradata/camera-feature.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libImageTagger.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libobjectcapture.arcsoft.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libobjectcapture_jni.arcsoft.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSmartScan.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"

LOG_STEP_IN "- Replacing SoundBooster"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver1100.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1070.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing GameDriver"
DELETE_FROM_WORK_DIR "system" "system/priv-app/DevGPUDriver-EX2200"
DELETE_FROM_WORK_DIR "system" "system/priv-app/GameDriver-EX2200"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-EX2100/GameDriver-EX2100.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/DevGPUDriver-EX2100/DevGPUDriver-EX2100.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Hotword"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx3CORTEXM4/HotwordEnrollmentOKGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx3CORTEXM4/HotwordEnrollmentXGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock NFC Case features"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.clearsideviewcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.sview.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.nfc_authentication_cover.xml" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT
