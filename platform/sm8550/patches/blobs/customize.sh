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

LOG_STEP_IN "- Adding HIDL face biometrics libs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/android.hardware.biometrics.face@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vendor.samsung.hardware.biometrics.face@2.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vendor.samsung.hardware.biometrics.face@3.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding QSEECOM blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/qseecomd" 0 0 755 "u:object_r:tee_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.hardware.qseecom@1.0-service" 0 0 755 "u:object_r:hal_drm_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libQSEEComAPI.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/com.qti.qseeaon.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/com.qti.qseeutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.qseecom@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.qseecom@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libQSEEComAPI.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/com.qti.qseeaon.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/com.qti.qseeutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.qseecom@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.qseecom@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/qseecomd.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.hardware.qseecom@1.0-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libQSEEComAPI_system.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.qseecom@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.qseecom-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libQSEEComAPI_system.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qseecom@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qseecom-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding VaultKeeper blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/vaultkeeperd" 0 0 755 "u:object_r:vaultkeeper_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/vendor.samsung.hardware.security.vaultkeeper@2.0-service" 0 0 755 "u:object_r:hal_vaultkeeper_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libhwvault.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vaultkeeper_common.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/vaultkeeper_manifest.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/vendor.samsung.hardware.security.vaultkeeper@2.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding VexFwk (Video Expert Framework) blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libandroid.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libcommon-jni.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libimgproc.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libmetadata.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libndk.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libruntime.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libsdk-v2-jni.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/vexfwk_service_aidl-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libandroid.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libcommon-jni.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libimgproc.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libmetadata.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libndk.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libruntime.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsdk-v2-jni.vexfwk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vexfwk_service_aidl-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/framework/vexfwk_service_lib.jar" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/vexfwk_service_lib.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-vexfwk.samsung.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/vexfwk_service/vexfwk_service.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding SNAP (AI/Neural Processing) blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.samsung.hardware.snap-service" 0 0 755 "u:object_r:hal_snap_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.samsung.hardware.securesnap-service" 0 0 755 "u:object_r:hal_snap_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/adsprpcd" 0 2000 755 "u:object_r:adsprpcd_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/cdsprpcd" 0 2000 755 "u:object_r:cdsprpcd_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libadsprpc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libadsp_default_listener.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_compute.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_compute_secure.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_compute_wrapper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_compute_wrapper_secure.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_qnn.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_vndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnap_vndk_secure.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnaplite_native.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnaplite_native_secure.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnaplite_wrapper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnaplite_wrapper_secure.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnapmw.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.snap-V1-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT


LOG_STEP_IN "- Adding display HAL services and blobs"
# Remove legacy display composer services (all versions)
LOG "- Removing legacy display composer services (if present)"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.1-service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.2-service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.3-service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.4-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.1-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.2-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.3-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.4-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer@2.1.xml"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer@2.2.xml"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer@2.3.xml"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer@2.4.xml"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer-qti-display.xml"

# Remove legacy memtrack service (HIDL version)
LOG "- Removing legacy memtrack service (if present)"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.memtrack@1.0-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.memtrack@1.0-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.memtrack@1.0.xml"

# Remove legacy display color service
LOG "- Removing legacy display color service (if present)"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/vendor.display.color@1.0-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/vendor.display.color@1.0-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/vendor.display.color@1.0.xml"

# Display composer service
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.hardware.display.composer-service" 0 2000 755 "u:object_r:hal_graphics_composer_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.hardware.display.composer-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/vendor.qti.hardware.display.composer-service.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Display allocator service
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.hardware.display.allocator-service" 0 2000 755 "u:object_r:hal_graphics_allocator_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.hardware.display.allocator-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/vendor.qti.hardware.display.allocator-service.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Display demura service
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.hardware.display.demura-service" 0 2000 755 "u:object_r:hal_display_demura_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.hardware.display.demura-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/vendor.qti.hardware.display.demura-service.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Display init files
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/hw/init.samsung.display.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/init.qti.display_boot.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Display config and color
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/snapdragon_color_libs_config.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Graphics mapper
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/android.hardware.graphics.mapper-impl-qti-display.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/android.hardware.graphics.mapper@4.0-impl-qti-display.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/android.hardware.graphics.mapper@4.0-impl-qti-display.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display composer libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.composer@3.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.composer@3.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.composer@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.composer@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/android.hardware.graphics.composer@2.4.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/android.hardware.graphics.composer@2.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/android.hardware.graphics.composer@2.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/android.hardware.graphics.composer@2.1.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display composer libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.composer@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.composer@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/android.hardware.graphics.composer@2.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/android.hardware.graphics.composer@2.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/android.hardware.graphics.composer@2.1.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display allocator libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.allocator@4.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.allocator@3.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.allocator@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display allocator libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.allocator@4.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.allocator@3.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.allocator@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display mapper libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapper@4.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapper@3.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapper@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapper@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapper@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapperextensions@1.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapperextensions@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapperextensions@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.mapperextensions@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display mapper libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapper@4.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapper@3.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapper@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapper@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapper@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapperextensions@1.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapperextensions@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapperextensions@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.mapperextensions@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display demura libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.demura@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display demura libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.demura@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display config libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.config-V6-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.config-V5-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.config-V4-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.config-V3-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.config-V2-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.display.config-V1-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.11.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.10.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.9.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.8.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.7.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.6.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.5.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.4.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.config@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display config libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.config-V6-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.config-V5-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.config-V4-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.config-V3-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.config-V2-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.display.config-V1-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.11.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.10.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.9.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.8.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.7.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.6.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.5.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.4.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.config@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display color libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.7.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.6.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.5.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.4.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.color@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.display.postproc@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnapdragoncolor-manager.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsnapdragoncolor-qdcm.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display color libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.7.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.6.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.5.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.4.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.3.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.color@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.display.postproc@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsnapdragoncolor-manager.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsnapdragoncolor-qdcm.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display core libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdmcore.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdmutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdmdal.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdmextension.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdm-color.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdm-colormgr-algo.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdm-disp-vndapis.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdisplayconfig.qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdisplaydebug.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdisplayqos.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdisplayskuutils.so" 0 0 644 "u:object_r:vendor_file:s0"

# Display core libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdmcore.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdmutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdmdal.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdmextension.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdm-color.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdm-colormgr-algo.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdm-disp-vndapis.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdisplayconfig.qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdisplaydebug.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdisplayqos.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdisplayskuutils.so" 0 0 644 "u:object_r:vendor_file:s0"

# Gralloc libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgralloc.qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgralloccore.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgrallocutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgralloc_helper.unifunc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgrallocusage.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqdMetaData.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdrmutils.so" 0 0 644 "u:object_r:vendor_file:s0"

# Gralloc libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libgralloc.qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libgralloccore.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libgrallocutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqdMetaData.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdrmutils.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding memtrack service"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.hardware.memtrack-service" 0 2000 755 "u:object_r:hal_memtrack_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/memtrack_qti.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/memtrack_qti.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding QCCSYSHAL service (system_ext)"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "bin/qccsyshal@1.2-service" 0 0 755 "u:object_r:qccsyshal_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "bin/qccsyshal_aidl-service" 0 0 755 "u:object_r:qccsyshal_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/init/vendor.qti.hardware.qccsyshal@1.2-service.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/init/vendor.qti.qccsyshal_aidl-service.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.qccsyshal@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.qccsyshal@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.qccsyshal@1.2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.qccsyshal_aidl-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qccsyshal@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qccsyshal@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qccsyshal@1.2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.qccsyshal_aidl-halimpl.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.qccsyshal_aidl-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
# Vendor libraries
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.qccsyshal@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.qccsyshal@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.qccsyshal@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.qccsyshal@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.qccsyshal@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.qccsyshal@1.2.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding QSPMHAL service (system_ext)"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "bin/qspmsvc" 0 0 755 "u:object_r:qspmsvc_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/init/qspmsvc.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libqspmsvc.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libqspmsvc.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.qspmhal@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.qspmhal-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.qspmhal@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.qspmhal-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
# Vendor libraries and rc file
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.qspmhal@1.0-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.qspmhal@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.qspmhal@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Camera ISP (Image Signal Processor) blobs"
# SwIsp (Software ISP) libraries - required for camera Super Night mode
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# AIQ (Auto Image Quality) Solution libraries - required for camera AI processing
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libAIQSolution_MPI.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Secure Element blobs"
# Remove legacy secure element services (if present)
LOG "- Removing legacy secure element services (if present)"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.secure_element@1.0-service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.secure_element@1.1-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.secure_element@1.0-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.secure_element@1.1-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.secure_element@1.0.xml"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.secure_element@1.1.xml"
# Add secure element @1.2 service and libraries
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/android.hardware.secure_element@1.2-service" 0 0 755 "u:object_r:hal_secure_element_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.secure_element@1.2-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsec_semRil.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/ese_spi_nxp.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsec_semRil.so" 0 0 644 "u:object_r:vendor_file:s0"
# Secure element power manager
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.esepowermanager@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.esepowermanager@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Security (KeyMint/KeyMaster) blobs"
# Remove legacy keymaster services @3.0 and @4.1 only (keep @4.0-strongbox)
LOG "- Removing legacy keymaster services (if present)"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.keymaster@3.0-service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.keymaster@4.1-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.keymaster@3.0-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.keymaster@4.1-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.keymaster@3.0.xml"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.keymaster@4.1.xml"
# Add Gatekeeper blobs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/android.hardware.gatekeeper@1.0-service" 0 0 755 "u:object_r:hal_gatekeeper_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.hardware.secureprocessor@1.0" 0 0 755 "u:object_r:vendor_qti_secure_processor_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.gatekeeper@1.0-service-qti.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.gatekeeper@1.0-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.hardware.secureprocessor@1.0.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/android.hardware.gatekeeper@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/android.hardware.gatekeeper@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/gatekeeper.mdfpp.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.secureprocessor.common@1.0-helper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.secureprocessor.common@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.secureprocessor.config@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.secureprocessor.device@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
# KeyMint service
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/android.hardware.security.keymint-service" 0 0 755 "u:object_r:hal_keymint_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.security.keymint-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/vintf/manifest/android.hardware.security.keymint-service-qti.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libcppbor_external.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libhermes_cred.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libkeymaster4_1support.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libskeymint10device.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libskeymint_cli.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.keymint-V2-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
# KeyMaster strongbox service
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/android.hardware.keymaster@4.0-strongbox-service-qti" 0 0 755 "u:object_r:hal_keymaster_qti_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.keymaster@4.0-strongbox-service-qti.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libkeymasterdeviceutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libspcom.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libkeymasterdeviceutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libkeymasterutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqtikeymaster4.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libspcom.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding FM Radio blobs"
# Add FM radio HAL and libraries
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.fm@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdsutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libidl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libmdmdetect.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqmi.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqmi_client_qmux.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqmiservices.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.fm@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.fm@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdsutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libidl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libmdmdetect.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqmi.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqmi_client_qmux.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqmiservices.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.fm@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Display Configuration Files"
# Display DPU configs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU660.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU670.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU720.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU7__.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU820.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU8__.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU9__.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/advanced_sf_offsets.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
# Backlight calibration files
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_r66451_amoled_cmd_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_r66451_amoled_video_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_cmd_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_qsync_cmd_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_qsync_video_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_video_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
# QDCM calibration data
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_DM2_S6E3FAC_AMB655AY01.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_2k_cmd_mode_qsync_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_2k_video_mode_qsync_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_4k_cmd_mode_dsc_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_4k_video_mode_dsc_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_qhd_cmd_mode_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_nt36672e_lcd_video_mode_dsi_novatek_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_nt36672e_lcd_video_mode_dsi_novatek_panel_without_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_cmd_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_cmd_mode_dsi_visionox_panel_without_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_video_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_video_mode_dsi_visionox_panel_without_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_sharp_1080p_cmd_mode_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_cmd_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_qsync_cmd_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_qsync_video_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_video_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/thermallevel_to_fps.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Bluetooth blobs"
# Bluetooth HAL service
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/android.hardware.bluetooth@1.1-service-qti" 0 0 755 "u:object_r:hal_bluetooth_default_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.bluetooth@1.1-service-qti.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Bluetooth libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.bttpi-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqti_vndfwk_detect_vendor.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsoc_helper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.bttpi-V2-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.samsung.hardware.bluetooth@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"

# Bluetooth libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.bttpi-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqti_vndfwk_detect_vendor.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsoc_helper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.bttpi-V2-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.bluetooth@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Bluetooth (A2DP) blobs"
# Bluetooth A2DP HAL implementations (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/android.hardware.bluetooth.audio@2.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/audio.bluetooth.default.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/audio.bluetooth_qti.default.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.bluetooth_audio@2.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.bluetooth_audio@2.1-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.bluetooth_sar@1.1-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.btconfigstore@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vendor.qti.hardware.btconfigstore@2.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"

# Bluetooth audio libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/com.qualcomm.qti.bluetooth_audio@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libbluetooth_audio_session.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libbluetooth_audio_session_aidl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libbluetooth_audio_session_aidl_qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libbluetooth_audio_session_qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libbluetooth_audio_session_qti_2_1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsehbluetooth_audio_session_aidl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.bluetooth_audio@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.bluetooth_audio@2.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.bluetooth_sar@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.bluetooth_sar@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.btconfigstore@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.qti.hardware.btconfigstore@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vendor.samsung.hardware.bluetooth.audio-V1-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"

# Bluetooth A2DP HAL implementations (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/android.hardware.bluetooth.audio@2.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/audio.bluetooth.default.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/audio.bluetooth_qti.default.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.bluetooth_audio@2.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.bluetooth_audio@2.1-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.bluetooth_sar@1.1-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.btconfigstore@1.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vendor.qti.hardware.btconfigstore@2.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"

# Bluetooth audio libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/com.qualcomm.qti.bluetooth_audio@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libbluetooth_audio_session.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libbluetooth_audio_session_aidl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libbluetooth_audio_session_aidl_qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libbluetooth_audio_session_qti.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libbluetooth_audio_session_qti_2_1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsehbluetooth_audio_session_aidl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.bluetooth_audio@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.bluetooth_audio@2.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.bluetooth_sar@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.bluetooth_sar@1.1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.btconfigstore@1.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.qti.hardware.btconfigstore@2.0.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.bluetooth.audio-V1-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Display blobs (system_ext)"
# Display color libraries (system_ext lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.color@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.color@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.color@1.2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.color@1.3.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Display config libraries (system_ext lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@1.2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@1.3.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@1.4.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@1.5.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.config@2.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.display.postproc@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Display config NDK libraries (system_ext lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V10-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V11-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V12-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V3-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V4-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V5-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V6-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V7-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V8-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.display.config-V9-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.qdutils_disp@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Display color libraries (system_ext lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.color@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.color@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.color@1.2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.color@1.3.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Display config libraries (system_ext lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@1.2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@1.3.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@1.4.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@1.5.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.config@2.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.display.postproc@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Display composer libraries (system_ext lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.composer@3.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.composer@3.1.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Display config NDK libraries (system_ext lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V1-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V10-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V11-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V12-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V3-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V4-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V5-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V6-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V7-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V8-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.display.config-V9-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.qdutils_disp@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding additional Display vendor blobs"
# EGL and Vulkan libraries (vendor lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/eglSubDriverAndroid.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/libEGL_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/libGLESv1_CM_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/libGLESv2_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/libVkLayer_ADRENO_qprofiler.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/libq3dtools_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/egl/libq3dtools_esx.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/gralloc.default.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/hw/vulkan.adreno.so" 0 0 644 "u:object_r:vendor_file:s0"

# Graphics libraries (vendor lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libEGL_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libadreno_utils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libgpu_tonemapper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libgsl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libintervmipc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libllvm-glnext.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libmemutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqservice.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdedrm.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libtestutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libtinyxml2_1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libvmfilexfer.so" 0 0 644 "u:object_r:vendor_file:s0"

# EGL and Vulkan libraries (vendor lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/eglSubDriverAndroid.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/libEGL_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/libGLESv1_CM_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/libGLESv2_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/libVkLayer_ADRENO_qprofiler.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/libq3dtools_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/egl/libq3dtools_esx.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/gralloc.default.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/hw/vulkan.adreno.so" 0 0 644 "u:object_r:vendor_file:s0"

# Graphics libraries (vendor lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libEGL_adreno.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libadreno_utils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgpu_tonemapper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libgsl.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libhistogram.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libintervmipc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libllvm-glnext.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libmemutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqservice.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsdedrm.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libtestutils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libtinyxml2_1.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libvmfilexfer.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding CDSP blobs"
# CDSP binaries and init files
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/cdsprpcd" 0 2000 755 "u:object_r:cdsprpcd_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.cdsprpc-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"

# CDSP libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libcdsp_default_listener.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libcdsprpc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libfastcvdsp_stub.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libfastcvopt.so" 0 0 644 "u:object_r:vendor_file:s0"

# CDSP libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libcdsp_default_listener.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libcdsprpc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libfastcvdsp_stub.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libfastcvopt.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding CVP blobs"
# CVP libraries (system_ext)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.cvp@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.cvp@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Media/Camera blobs"
# Media seccomp policy
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "etc/seccomp_policy/mediacodec.policy" 0 0 644 "u:object_r:system_file:s0"

# Media libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/graphicbuffersource-aidl-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libaconfig_storage_read_api_cc.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libdatasource.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libdatasource_local_cache.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libmedia_codeclist.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libmedia_codeclist_capabilities.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libstagefright_aidl_bufferpool2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libstagefright_bufferpool@2.0.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libstagefright_codecbase.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libstagefright_framecapture_utils.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libstagefright_graphicbuffersource_aidl.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib/libstagefright_surface_utils.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Media libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/graphicbuffersource-aidl-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libaconfig_storage_read_api_cc.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libdatasource.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libdatasource_local_cache.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libhdcp_client_aidl.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libmedia_codeclist.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libmedia_codeclist_capabilities.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_aidl_bufferpool2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_bufferpool@2.0.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_codecbase.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_framecapture_utils.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_graphicbuffersource_aidl.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_httplive_sec.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/libstagefright_surface_utils.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so" 0 0 644 "u:object_r:system_lib_file:s0"

# VPP libraries (system_ext)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.vpp@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.vpp@1.1.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Media HAL services
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/android.hardware.media.omx@1.0-service" 0 0 755 "u:object_r:mediacodec_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.media.c2@1.0-service" 0 0 755 "u:object_r:vendor_qti_media_c2_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/hw/vendor.qti.media.c2audio@1.0-service" 0 0 755 "u:object_r:vendor_qti_media_c2_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/android.hardware.media.omx@1.0-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.media.c2@1.0-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.media.c2audio@1.0-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"

# Vendor media libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libFrucSSMLib.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libOmxCore.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libcodecsolutionhelper_vendor.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libdspmc_wrapper.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libgaya.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libplatformconfig.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libpredeflicker_native.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqc2audio_base.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqc2audio_basecodec.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqc2audio_core.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqc2audio_hooks.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqc2audio_platform.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libqc2audio_utils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/librechdr10plus.sec.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/librechdr10plus.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsavscmn.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libsdynatm.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libstagefright_bufferqueue_helper_vendor.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libstagefright_omx_vendor.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libstagefright_softomx_plugin.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libstagefrighthw.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libvicom.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/vintf-codecsolution-V2-ndk.so" 0 0 644 "u:object_r:vendor_file:s0"

# Vendor media libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libOmxCore.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libplatformconfig.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqc2audio_base.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqc2audio_basecodec.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqc2audio_core.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqc2audio_hooks.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqc2audio_platform.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libqc2audio_utils.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libsavscmn.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libstagefright_foundation_vendor.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libstagefrighthw.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Dolby blobs"
# Dolby configuration
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/dolby/dax-default.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libdeccfg.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT
