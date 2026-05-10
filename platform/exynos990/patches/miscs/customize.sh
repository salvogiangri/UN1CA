LOG_STEP_IN "- Setting casefold props"
SET_PROP "vendor" "external_storage.projid.enabled" "1"
SET_PROP "vendor" "external_storage.casefold.enabled" "1"
SET_PROP "vendor" "external_storage.sdcardfs.enabled" "0"
SET_PROP "vendor" "persist.sys.fuse.passthrough.enable" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling IncrementalFS"
SET_PROP "vendor" "ro.incremental.enable" "yes"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling FS Verity"
SET_PROP "vendor" "ro.apk_verity.mode" "2"
LOG_STEP_OUT

LOG_STEP_IN "- Setting SF flags"
SET_PROP "vendor" "debug.sf.latch_unsignaled" "1"
SET_PROP "vendor" "debug.sf.high_fps_late_app_phase_offset_ns" "0"
SET_PROP "vendor" "debug.sf.high_fps_late_sf_phase_offset_ns" "0"
LOG_STEP_OUT

LOG_STEP_IN "- Setting Adaptive HFR flags"
if [[ "$TARGET_CODENAME" != "c1s" && "$TARGET_CODENAME" != "c2s" ]]; then
    SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms" "250"
    SET_PROP "vendor" "ro.surface_flinger.set_touch_timer_ms" "300"
    SET_PROP "vendor" "ro.surface_flinger.set_display_power_timer_ms" "200"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
elif [[ "$TARGET_CODENAME" == "c1s" ]]; then
    SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "false"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "false"
elif [[ "$TARGET_CODENAME" == "c2s" ]]; then
    SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
fi
LOG_STEP_OUT

LOG_STEP_IN "- Enabling Vulkan"
SET_PROP "vendor" "ro.hwui.use_vulkan" "true"
SET_PROP "vendor" "debug.hwui.use_hint_manager" "true"
LOG_STEP_OUT

LOG "- Disabling encryption"
LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.exynos990")
sed -i "${LINE}s/,fileencryption=ice//g" "$WORK_DIR/vendor/etc/fstab.exynos990"

# ODE
sed -i -e "/ODE/d" -e "/keydata/d" -e "/keyrefuge/d" "$WORK_DIR/vendor/etc/fstab.exynos990"

# For some reason we are missing 2 permissions here: android.hardware.security.model.compatible and android.software.controls
# First one is related to encryption and second one to SmartThings Device Control
LOG "- Patching vendor permissions"
sed -i '$d' "$WORK_DIR/vendor/etc/permissions/handheld_core_hardware.xml"
{
    echo ""
    echo "    <!-- Indicate support for the Android security model per the CDD. -->"
    echo "    <feature name=\"android.hardware.security.model.compatible\"/>"
    echo ""
    echo "    <!--  Feature to specify if the device supports controls.  -->"
    echo "    <feature name=\"android.software.controls\"/>"
    echo "</permissions>"
} >> "$WORK_DIR/vendor/etc/permissions/handheld_core_hardware.xml"

LOG_STEP_IN "- Setting stock Bluetooth profiles"
SET_PROP "product" "bluetooth.profile.asha.central.enabled" "true"
SET_PROP "product" "bluetooth.profile.a2dp.source.enabled" "true"
SET_PROP "product" "bluetooth.profile.avrcp.target.enabled" "true"
SET_PROP "product" "bluetooth.profile.bap.broadcast.assist.enabled" "false"
SET_PROP "product" "bluetooth.profile.bap.broadcast.source.enabled" "false"
SET_PROP "product" "bluetooth.profile.bap.unicast.client.enabled" "false"
SET_PROP "product" "bluetooth.profile.bas.client.enabled" "false"
SET_PROP "product" "bluetooth.profile.csip.set_coordinator.enabled" "false"
SET_PROP "product" "bluetooth.profile.gatt.enabled" "true"
SET_PROP "product" "bluetooth.profile.hap.client.enabled" "false"
SET_PROP "product" "bluetooth.profile.hfp.ag.enabled" "true"
SET_PROP "product" "bluetooth.profile.hid.device.enabled" "true"
SET_PROP "product" "bluetooth.profile.hid.host.enabled" "true"
SET_PROP "product" "bluetooth.profile.map.server.enabled" "true"
SET_PROP "product" "bluetooth.profile.mcp.server.enabled" "false"
SET_PROP "product" "bluetooth.profile.opp.enabled" "false"
SET_PROP "product" "bluetooth.profile.pan.nap.enabled" "true"
SET_PROP "product" "bluetooth.profile.pan.panu.enabled" "true"
SET_PROP "product" "bluetooth.profile.pbap.server.enabled" "true"
SET_PROP "product" "bluetooth.profile.sap.server.enabled" "true"
SET_PROP "product" "bluetooth.profile.ccp.server.enabled" "false"
SET_PROP "product" "bluetooth.profile.vcp.controller.enabled" "false"

if [[ "$TARGET_CODENAME" == "r8s" ]]; then
    ADD_TO_WORK_DIR "r11sxxx" "system" "system/apex/com.android.bt.apex" 0 0 644 "u:object_r:system_file:s0"
else
    ADD_TO_WORK_DIR "b0sxxx" "system" "system/apex/com.android.bt.apex" 0 0 644 "u:object_r:system_file:s0"
fi
LOG_STEP_OUT
