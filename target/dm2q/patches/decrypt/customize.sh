# shellcheck shell=bash
LOG "- Disabling encryption in /vendor/etc/fstab.qcom"
LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.qcom")
EVAL "sed -i \"${LINE}s/,fileencryption=aes-256-xts:aes-256-cts:v2//g\" \"$WORK_DIR/vendor/etc/fstab.qcom\"" || return 1
