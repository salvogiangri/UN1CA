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
