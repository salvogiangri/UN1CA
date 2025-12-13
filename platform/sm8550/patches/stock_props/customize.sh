LOG "- Adding \"ro.netflix.bsp_rev\" prop with \"Q8550-36432-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q8550-36432-1\" \"$WORK_DIR/system/system/build.prop\""

SET_PROP "vendor" "ro.product.vendor.device" "${TARGET_CODENAME}xxx"
