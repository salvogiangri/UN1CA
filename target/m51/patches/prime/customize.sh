LOG_STEP_IN "- Replacing the default kernel with Prime Kernel"
rm -rf "$WORK_DIR/kernel/"*
cp -af "$MODPATH/kernel/." "$WORK_DIR/kernel/"
LOG_STEP_OUT
