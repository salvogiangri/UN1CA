LOG_STEP_IN "- Adding dm3qxxx Flashlight blobs"
DELETE_FROM_WORK_DIR "vendor" "etc/init/hw/init.y2q.rc"
ADD_TO_WORK_DIR "dm3qxxx" "vendor" "etc/init/hw/init.y2q.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT
