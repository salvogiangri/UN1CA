LOG_STEP_IN "- Adding \"ro.netflix.bsp_rev\" prop with \"Q7250-19133-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q7250-19133-1\" \"$WORK_DIR/system/system/build.prop\""
LOG_STEP_OUT 

LOG_STEP_IN "- Removing frp"
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "vendor" "ro.frp.pst" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Removing media.extractor.sec.pcm-32bit prop"
SET_PROP "system" "media.extractor.sec.pcm-32bit" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Fixing edge lighting"
SET_PROP "system" "ro.factory.model" "SM-M515F"
LOG_STEP_OUT 

LOG_STEP_IN "- Increasing audio buffer size to 1024 kb"
SET_PROP "vendor" "vendor.audio.offload.buffer.size.kb" "1024"
LOG_STEP_OUT 

LOG_STEP_IN "- Decreasing touch latency"
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
LOG "- Adding \"ro.surface_flinger.set_idle_timer_ms\" prop with \"4000\" in /vendor/default.prop"
EVAL "sed -i \"/use_content_detection/a ro.surface_flinger.set_idle_timer_ms=4000\" \"$WORK_DIR/vendor/default.prop\""
LOG "- Adding \"ro.surface_flinger.set_touch_timer_ms\" prop with \"4000\" in /vendor/default.prop"
EVAL "sed -i \"/set_idle_timer_ms/a ro.surface_flinger.set_touch_timer_ms=4000\" \"$WORK_DIR/vendor/default.prop\""
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
LOG_STEP_OUT