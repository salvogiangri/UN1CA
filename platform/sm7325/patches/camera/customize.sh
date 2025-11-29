# Add ImageTagger blobs
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libImageTagger.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add Polarr blobs
ADD_TO_WORK_DIR "a73xqxx" "system" "system/etc/public.libraries-polarr.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libBestComposition.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libFeature.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libPolarrSnap.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libTracking.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libYuv.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"

if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    # Upgrade midas blobs
    DELETE_FROM_WORK_DIR "vendor" "etc/midas"
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/midas" 0 2000 755 "u:object_r:vendor_configs_file:s0"

    # Upgrade singletake blobs
    DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/singletake" 0 2000 755 "u:object_r:vendor_configs_file:s0"
fi

if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
    LOG "- Patching /vendor/ueventd.rc"
    EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/ueventd.rc\""
fi
