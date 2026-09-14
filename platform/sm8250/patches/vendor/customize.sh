LOG_STEP_IN "- Adding AIDL vibrator HAL"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.0.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.1.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.2.so"
LOG "- Patching /vendor/etc/vintf/manifest.xml"
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.vibrator/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/vendor.samsung.hardware.vibrator/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "bin/hw/vendor.samsung.hardware.vibrator-service" 0 2000 755 "u:object_r:hal_vibrator_default_exec:s0"
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "etc/init/vendor.samsung.hardware.vibrator-default.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/libsnaplite_native.so" 0 0 644 "u:object_r:same_process_hal_file:s0"

if [[ "$TARGET_CODENAME" == "x1q" || \
      "$TARGET_CODENAME" == "y2q" || \
      "$TARGET_CODENAME" == "z3q" || \
      "$TARGET_CODENAME" == "c1q" || \
      "$TARGET_CODENAME" == "c2q" ]]; then
    LOG_STEP_IN "- Adding dm3qxxx light blobs"
    ADD_TO_WORK_DIR "dm3qxxx" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
    ADD_TO_WORK_DIR "dm3qxxx" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
    LOG_STEP_OUT
fi

if [[ "$TARGET_CODENAME" == "x1q" || \
      "$TARGET_CODENAME" == "y2q" || \
      "$TARGET_CODENAME" == "z3q" || \
      "$TARGET_CODENAME" == "c1q" || \
      "$TARGET_CODENAME" == "c2q" ]]; then
    LOG_STEP_IN "- Adding dm3qxxx wifi blobs"
    ADD_TO_WORK_DIR "dm3qxxx" "vendor" "bin/hw/wpa_supplicant" 0 2000 755 "u:object_r:hal_wifi_supplicant_default_exec:s0"
    LOG_STEP_OUT
fi


LOG_STEP_IN "- Adding a73xqxx MIDAS"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/midas"
LOG_STEP_OUT

LOG_STEP_IN "- Adding 32-bit WFD blobs"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp2.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplay_wfd.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplayservice.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsecuibc.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libstagefright_hdcp.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/bin/insthk" 0 2000 755 "u:object_r:insthk_exec:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/bin/remotedisplay" 0 2000 755 "u:object_r:remotedisplay_exec:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libremotedisplay_wfd.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libremotedisplayservice.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libsecuibc.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libstagefright_hdcp.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/wfd_log.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Setting Adaptive HFR flags"
    SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms" "250"
    SET_PROP "vendor" "ro.surface_flinger.set_touch_timer_ms" "300"
    SET_PROP "vendor" "ro.surface_flinger.set_display_power_timer_ms" "200"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling Vulkan"
SET_PROP "vendor" "ro.hwui.use_vulkan" "true"
LOG_STEP_OUT

LOG_STEP_IN "- wifi+security Prop"
SET_PROP "vendor" "wlan.wfd.hdcp" "disabled"
SET_PROP "vendor" "wifi.interface" "wlan0"
SET_PROP "vendor" "ro.security.vaultkeeper.native" "0"
SET_PROP "vendor" "ro.security.vaultkeeper.feature" "0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing singletake blobs with dm3qxxx"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "dm3qxxx" "vendor" "etc/singletake" 0 0 755 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Removing configstore-1.1 service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.configstore@1.1-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.configstore@1.1-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/seccomp_policy/configstore@1.1.policy"
LOG_STEP_OUT
