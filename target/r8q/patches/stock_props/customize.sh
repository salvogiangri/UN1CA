LOG "- Adding \"ro.netflix.bsp_rev\" prop with \"Q8250-19134-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q8250-19134-1\" \"$WORK_DIR/system/system/build.prop\""
