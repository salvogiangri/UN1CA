SKIPUNZIP=1

HAL_LIBS="
$WORK_DIR/vendor/lib/hw/camera.qcom.so
$WORK_DIR/vendor/lib/hw/com.qti.chi.override.so
$WORK_DIR/vendor/lib64/hw/camera.qcom.so
$WORK_DIR/vendor/lib64/hw/com.qti.chi.override.so
"
for f in $HAL_LIBS; do
    sed -i "s/ro.boot.flash.locked/ro.camera.notify_nfc/g" "$f"
done
