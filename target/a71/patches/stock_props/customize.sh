LOG "- Adding \"ro.netflix.bsp_rev\" prop with \"Q7250-19133-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q7250-19133-1\" \"$WORK_DIR/system/system/build.prop\""
