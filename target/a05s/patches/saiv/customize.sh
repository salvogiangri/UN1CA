LOG_STEP_IN "- Adding missing MIDAS blobs"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/midas" 0 2000 755 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/VslMesDetector" 0 2000 755 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT
