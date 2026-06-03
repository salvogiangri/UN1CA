# Set default SIM count to 1
# Before: [mov w0, #0x2]
# After: [mov w0, #0x1]
HEX_PATCH "$WORK_DIR/vendor/bin/secril_config_svc" "40008052" "20008052"
