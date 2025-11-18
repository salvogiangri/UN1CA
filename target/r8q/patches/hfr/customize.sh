# https://android.googlesource.com/platform/frameworks/native/+/refs/tags/android-16.0.0_r2/services/surfaceflinger/Scheduler/RefreshRateSelector.h#314
IDLE_TIMER_MS=200
# https://android.googlesource.com/platform/frameworks/native/+/refs/tags/android-16.0.0_r2/services/surfaceflinger/sysprop/SurfaceFlingerProperties.sysprop#346
TOUCH_TIMER_MS=300

SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
LOG "- Adding \"ro.surface_flinger.set_idle_timer_ms\" prop with \"$IDLE_TIMER_MS\" in /vendor/default.prop"
EVAL "sed -i \"/use_content_detection/a ro.surface_flinger.set_idle_timer_ms=$IDLE_TIMER_MS\" \"$WORK_DIR/vendor/default.prop\""
LOG "- Adding \"ro.surface_flinger.set_touch_timer_ms\" prop with \"$TOUCH_TIMER_MS\" in /vendor/default.prop"
EVAL "sed -i \"/set_idle_timer_ms/a ro.surface_flinger.set_touch_timer_ms=$TOUCH_TIMER_MS\" \"$WORK_DIR/vendor/default.prop\""
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"

unset IDLE_TIMER_MS TOUCH_TIMER_MS
