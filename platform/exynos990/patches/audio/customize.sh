BLOBS_LIST="
lib/android.hardware.audio.common@5.0-util.so
lib/hw/android.hardware.audio.effect@5.0-impl.so
lib/hw/android.hardware.audio@5.0-impl.so
lib64/android.hardware.audio.common@5.0-util.so
lib64/hw/android.hardware.audio.effect@5.0-impl.so
lib64/hw/android.hardware.audio@5.0-impl.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "vendor" "$blob"
done
