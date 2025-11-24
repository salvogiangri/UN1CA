echo "Add stock camera libs"
BLOBS_LIST="
system/etc/public.libraries-arcsoft.txt
system/etc/public.libraries-camera.samsung.txt
system/lib64/libaiclearzoom_raw.arcsoft.so
system/lib64/libaiclearzoomraw_wrapper_v1.camera.samsung.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done
