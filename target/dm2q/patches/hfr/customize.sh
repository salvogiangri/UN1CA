# https://android.googlesource.com/platform/frameworks/native/+/refs/tags/android-16.0.0_r2/services/surfaceflinger/Scheduler/RefreshRateSelector.h#314
IDLE_TIMER_MS=250
# https://android.googlesource.com/platform/frameworks/native/+/refs/tags/android-16.0.0_r2/services/surfaceflinger/sysprop/SurfaceFlingerProperties.sysprop#346
TOUCH_TIMER_MS=300

# Surface Flinger refresh rate properties
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
LOG "- Adding \"ro.surface_flinger.set_idle_timer_ms\" prop with \"$IDLE_TIMER_MS\" in /vendor/build.prop"
EVAL "sed -i \"/use_content_detection/a ro.surface_flinger.set_idle_timer_ms=$IDLE_TIMER_MS\" \"$WORK_DIR/vendor/build.prop\""
LOG "- Adding \"ro.surface_flinger.set_touch_timer_ms\" prop with \"$TOUCH_TIMER_MS\" in /vendor/build.prop"
EVAL "sed -i \"/set_idle_timer_ms/a ro.surface_flinger.set_touch_timer_ms=$TOUCH_TIMER_MS\" \"$WORK_DIR/vendor/build.prop\""
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"

# Surface Flinger phase offset properties for high refresh rate
SET_PROP "vendor" "debug.sf.enable_advanced_sf_phase_offset" "0"
SET_PROP "vendor" "debug.sf.use_phase_offsets_as_durations" "0"
SET_PROP "vendor" "debug.sf.early_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.early_app_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.early_gl_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.early_gl_app_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.high_fps_early_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.high_fps_early_gl_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.high_fps_late_app_phase_offset_ns" "100000"
SET_PROP "vendor" "debug.sf.high_fps_late_sf_phase_offset_ns" "100000"

# Debug refresh rate overlay
SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"

unset IDLE_TIMER_MS TOUCH_TIMER_MS
