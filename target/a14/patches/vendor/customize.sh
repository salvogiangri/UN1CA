LOG_STEP_IN "-Replacing fstab with prebuilt"
DELETE_FROM_WORK_DIR "vendor" "etc/fstab.s5e3830"
ADD_TO_WORK_DIR "$SRC_DIR/target/a14/patches/vendor/files" "vendor" "etc/fstab.s5e3830" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT
