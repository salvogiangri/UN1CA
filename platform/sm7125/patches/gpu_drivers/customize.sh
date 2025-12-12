LOCAL_PATH="$SRC_DIR/platform/$TARGET_PLATFORM/patches/gpu_drivers"

LOG_STEP_IN "- Downloading GPU drivers"
git clone --depth=1 https://github.com/frstprjkt/gpu_drivers -b A736BXXSAGYJ3 $LOCAL_PATH/vendor
rm -rf $LOCAL_PATH/vendor/.git
LOG_STEP_OUT

LOG_STEP_IN "- Adding downloaded GPU drivers"
ADD_TO_WORK_DIR "$LOCAL_PATH" "vendor" "." 0 2000 755 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Cleaning patch directory"
rm -rf $LOCAL_PATH/vendor
LOG_STEP_OUT
