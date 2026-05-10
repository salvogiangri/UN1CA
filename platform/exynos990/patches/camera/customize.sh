LOG_STEP_IN "- Replacing camera blobs"
BLOBS_LIST="
system/lib64/libenn_wrapper_system.so
system/lib64/libpic_best.arcsoft.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libdualcam_refocus_gallery_54.so
system/lib64/libdualcam_refocus_gallery_48.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libface_recognition.arcsoft.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

BLOBS_LIST="
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libMultiFrameProcessing20.camera.samsung.so
system/lib64/libMultiFrameProcessing20Core.camera.samsung.so
system/lib64/libMultiFrameProcessing20Day.camera.samsung.so
system/lib64/libMultiFrameProcessing20Tuning.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libGeoTrans10.so
system/lib64/vendor.samsung_slsi.hardware.geoTransService@1.0.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done

if [[ "$TARGET_CODENAME" == "c1s" || "$TARGET_CODENAME" == "c2s" ]]; then
    BLOBS_LIST="
    system/lib64/libofi_seva.so
    system/lib64/libofi_klm.so
    system/lib64/libofi_plugin.so
    system/lib64/libofi_rt_framework_user.so
    system/lib64/libofi_service_interface.so
    system/lib64/libofi_gc.so
    system/lib64/vendor.samsung_slsi.hardware.ofi@2.0.so
    system/lib64/vendor.samsung_slsi.hardware.ofi@2.1.so
    "
    for blob in $BLOBS_LIST
    do
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
    done
fi

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

LOG_STEP_OUT

LOG_STEP_IN "- Adding libc++_shared.so dependency for __cxa_demangle symbol"
patchelf --add-needed "libc++_shared.so" "$WORK_DIR/system/system/lib64/libMultiFrameProcessing20Core.camera.samsung.so"
LOG_STEP_OUT

LOG_STEP_IN
LOG "- Patching Video SVC Check"
# Early jump after the log and abort functions when configureSVC fails
# b LAB_001dd448 -> b LAB_001ddc24
HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" "da4a0594e0031a2a22feff17" "da4a0594e0031a2a19000014"


LOG "- Patching HDR10+ Check"
# Skip HDR10+ Recording ASSERT
# cbz this,LAB_001dde38 -> nop
HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" "010140f90a4d0594604d0034" "010140f90a4d05941f2003d5"
LOG_STEP_OUT

LOG_STEP_IN "- Adding prebuilt libs from other devices"
BLOBS_LIST="
system/lib64/libc++_shared.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "e2sxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done

BLOBS_LIST="
system/lib64/libeden_wrapper_system.so
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3sxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 (p3sxxx) SWISP models"
DELETE_FROM_WORK_DIR "vendor" "saiv/swisp_1.0"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "saiv/swisp_1.0"

BLOBS_LIST="
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3sxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done
LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 (p3sxxx) SingleTake models"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "etc/singletake"

BLOBS_LIST="
system/priv-app/SingleTakeService/SingleTakeService.apk
system/cameradata/singletake/service-feature.xml
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3sxxx" "system" "$blob" 0 0 644 "u:object_r:system_file:s0" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

LOG_STEP_OUT
