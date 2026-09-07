# Set default SIM count to 1
# Before: [mov w1, #0x2]
# After: [mov w1, #0x1]
HEX_PATCH "$WORK_DIR/vendor/bin/secril_config_svc" "41008052" "21008052"
