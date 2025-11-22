LOG "- Adding \"ro.netflix.bsp_rev\" prop with \"Q875-32408-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q875-32408-1\" \"$WORK_DIR/system/system/build.prop\""
