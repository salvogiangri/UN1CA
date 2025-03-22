SKIPUNZIP=1

# [
DECOMPILE()
{
    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        bash "$SRC_DIR/scripts/apktool.sh" d "$1"
    fi
}

APPLY_PATCH()
{
    local PATCH
    local COMMIT_NAME
    local OUT

    DECOMPILE "$1"

    cd "$APKTOOL_DIR/$1"
    PATCH="$SRC_DIR/unica/patches/knoxpatch/$2"
    COMMIT_NAME="$(grep "^Subject:" "$PATCH" | sed 's/.*PATCH] //')"
    echo "Applying \"$COMMIT_NAME\" to /$1"
    OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
        || echo "$OUT" | grep -q "Skipping patch" || false
    patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
    cd - &> /dev/null
}
# ]

REMOVE_FROM_WORK_DIR "system" "system/etc/public.libraries-wsm.samsung.txt"
REMOVE_FROM_WORK_DIR "system" "system/lib/libhal.wsm.samsung.so"
REMOVE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/libhal.wsm.samsung.so"
REMOVE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"

if [ -f "$WORK_DIR/system/system/priv-app/KmxService/KmxService.apk" ]; then
    APPLY_PATCH "system/priv-app/KmxService/KmxService.apk" "kmx/KmxService.apk/0001-Nuke-ROT-IntegrityStatus-check.patch"
fi
