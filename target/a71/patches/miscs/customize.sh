# Use TEE SPI in setCosNameProp()
HEX_PATCH "$WORK_DIR/system/system/bin/sem_daemon" \
    "e0031f2a09060094" \
    "2000805209060094"
