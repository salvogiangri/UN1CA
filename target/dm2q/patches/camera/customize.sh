echo "Add stock camera libs"
BLOBS_LIST="
system/lib64/libDLInterface_aidl.camera.samsung.so
system/lib64/libDocDeblur.camera.samsung.so
system/lib64/libDocObjectRemoval.camera.samsung.so
system/lib64/libDocObjectRemoval.enhanceX.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done
