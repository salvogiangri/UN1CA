DELETE_FROM_WORK_DIR "system" "system/etc/public.libraries-wsm.samsung.txt"
DELETE_FROM_WORK_DIR "system" "system/lib/libhal.wsm.samsung.so"
DELETE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhal.wsm.samsung.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"

if [ -f "$WORK_DIR/system/system/priv-app/KmxService/KmxService.apk" ]; then
    APPLY_PATCH "system" "system/priv-app/KmxService/KmxService.apk" "$SRC_DIR/unica/mods/knoxpatch/kmx/KmxService.apk/0001-Nuke-ROT-IntegrityStatus-check.patch"
fi
