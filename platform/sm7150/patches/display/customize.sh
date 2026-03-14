# https://github.com/pascua28/UN1CA/tree/sixteen/target/a71/patches/display

LOG_STEP_IN "- Removing legacy display composer"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.4-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.4-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer-qti-display.xml"
LOG_STEP_OUT

LOG_STEP_IN "- Adding AIDL display composer from r8qxxx"
ADD_TO_WORK_DIR "r8qxxx" "vendor" "."

EVAL "mv \"$WORK_DIR/vendor/lib64/hw/lights.kona.so\" \"$WORK_DIR/vendor/lib64/hw/lights.sm6150.so\""
EVAL "mv \"$WORK_DIR/vendor/lib64/hw/memtrack.kona.so\" \"$WORK_DIR/vendor/lib64/hw/memtrack.sm6150.so\""

HEX_PATCH "$WORK_DIR/vendor/lib64/libsdmutils.so" "40F9F303012A3401" "40F9130080523401"

# Workaround getMetaData() return path to fix GetCustomDimensions() error (from r9q).
# Un-inline pixel format checks from:
# if (format != HAL_PIXEL_FORMAT_YCbCr_420_SP_VENUS_UBWC || format != HAL_PIXEL_FORMAT_YCbCr_420_TP10_UBWC ||
#      format != HAL_PIXEL_FORMAT_YCbCr_420_P010_UBWC)
# to:
# if (!IsUBwcFormat())
# to retain padding and file size
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "60040035a8c35eb828040034a82e40b9" "e803002ae0031f2a28040035a8c35eb8"
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "1f910471200100542981815269f4af72" "e8030034a82e40b9e003082a75feff97"
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "1f01096ba0000054c980815269f4af72" "e803002ae0031f2a280300341f2003d5"
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "1f01096bc1020054bf431ef8a9aa4329" "1f2003d51f2003d5bf431ef8a9aa4329"
LOG_STEP_OUT