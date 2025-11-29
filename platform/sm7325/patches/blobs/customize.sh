LOG_STEP_IN "- Adding OK Google Hotword Enrollment blobs"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON" 0 0 755 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3HEXAGON" 0 0 755 "u:object_r:system_file:s0"
LOG_STEP_OUT

if [ "$TARGET_PRODUCT_SHIPPING_API_LEVEL" -gt "30" ]; then
    LOG_STEP_IN "- Adding stock WFD blobs"
    ADD_TO_WORK_DIR "a73xqxx" "system" "system/bin/insthk" 0 2000 755 "u:object_r:insthk_exec:s0"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
    ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libstagefright_hdcp.so" 0 0 644 "u:object_r:system_lib_file:s0"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
    LOG_STEP_OUT
else
    LOG_STEP_IN "- Adding 32-bit WFD blobs"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/bin/insthk" 0 2000 755 "u:object_r:insthk_exec:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/bin/remotedisplay" 0 2000 755 "u:object_r:remotedisplay_exec:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libremotedisplay_wfd.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libremotedisplayservice.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libsecuibc.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libstagefright_hdcp.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/wfd_log.so" 0 0 644 "u:object_r:system_lib_file:s0"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp2.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplay_wfd.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplayservice.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libsecuibc.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libstagefright_hdcp.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/wfd_log.so"
    LOG_STEP_OUT
fi

ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"

LOG_STEP_IN "- Adding HIDL face biometrics libs"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/android.hardware.biometrics.face@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/vendor.samsung.hardware.biometrics.face@2.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
if [ "$TARGET_PLATFORM_SDK_VERSION" -ge "34" ]; then
    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/vendor.samsung.hardware.biometrics.face@3.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
LOG_STEP_OUT

LOG_STEP_IN "- Adding keymaster 4.0 libs"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/android.hardware.keymaster@3.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/android.hardware.keymaster@4.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/android.hardware.keymaster@4.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/android.hardware.security.keymint-V1-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib/android.hardware.security.secureclock-V1-ndk.so"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/lib_nativeJni.dk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libdk_native_keymaster.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/libdk_native_keymint.so"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libkeymaster4_1support.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libkeymaster4support.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.keymint-V1-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/android.hardware.security.keymint-V1-ndk.so"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib64/lib_nativeJni.dk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/libdk_native_keymint.so"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib64/libdk_native_keymaster.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.keymint-V1-ndk.so"
LOG_STEP_OUT

if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "bin/hw/wpa_supplicant" 0 2000 755 "u:object_r:hal_wifi_supplicant_default_exec:s0"
fi
