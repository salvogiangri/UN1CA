LOG_STEP_IN "- Adding \"ro.netflix.bsp_rev\" prop with \"Q7250-19133-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q7250-19133-1\" \"$WORK_DIR/system/system/build.prop\""
LOG_STEP_OUT 

LOG_STEP_IN "- Disabling frp"
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "vendor" "ro.frp.pst" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Disabling media.extractor.sec.pcm-32bit"
SET_PROP "system" "media.extractor.sec.pcm-32bit" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Fixing edge lighting"
SET_PROP "system" "ro.factory.model" "SM-M515F"
LOG_STEP_OUT 

LOG_STEP_IN "- Increasing audio buffer size to 1024"
SET_PROP "vendor" "vendor.audio.offload.buffer.size.kb" "1024"
LOG_STEP_OUT 