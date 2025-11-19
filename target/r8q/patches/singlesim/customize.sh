# Set default SIM count to 1
# Before: [mov w8, #0x2]
# After: [mov w8, #0x1]
HEX_PATCH "$WORK_DIR/vendor/bin/secril_config_svc" "48008052" "28008052"
