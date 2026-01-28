if [[ "$TARGET_CODENAME" != "beyond0lte" && "$TARGET_CODENAME" != "beyondx" ]]; then
    LOG_STEP_IN "- Adding stock HRM blobs"
    BLOBS_LIST="
    system/etc/permissions/privapp-permissions-com.sec.android.service.health.xml
    system/etc/permissions/android.hardware.sensor.heartrate.xml
    system/etc/permissions/com.sec.feature.spo2.xml
    system/lib64/libhr.so
    "
    for blob in $BLOBS_LIST
    do
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob"
    done
    LOG_STEP_OUT
else
    LOG "- $TARGET_CODENAME detected. Skipping."
fi
