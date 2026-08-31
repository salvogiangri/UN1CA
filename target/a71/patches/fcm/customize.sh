LOG "- Patching /vendor/etc/vintf/manifest.xml"
EVAL "sed -i \"s/type=\\\"device\\\" target-level=\\\"4\\\">/type=\\\"device\\\" target-level=\\\"5\\\">/\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.configstore/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
EVAL "sed -i \"/^<\/manifest>\\\$/i\\\\    <kernel target-level=\\\"5\\\"\/>\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""

DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.configstore@1.1-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.configstore@1.1-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/seccomp_policy/configstore@1.1.policy"
