# Fix Photo Remaster
EVAL "echo \"ro.midas.device u:object_r:build_prop:s0 exact string\"  >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""
SET_PROP "system" "ro.midas.device" "a54x"
HEX_PATCH "$WORK_DIR/system/system/lib64/libmidas_core.camera.samsung.so" \
    "726f2e70726f647563742e646576696365" "726f2e6d696461732e6465766963650000"
