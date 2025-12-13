EUREKA_ZIP="$(curl -s "https://api.github.com/repos/saadelasfur/eureka_releases/releases/latest" \
    | jq -r ".assets[] | .browser_download_url" \
    | grep "Vanilla" | grep "r9q2.zip")"

[ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

LOG_STEP_IN "- Downloading $(basename "$EUREKA_ZIP")"
DOWNLOAD_FILE "$EUREKA_ZIP" "$TMP_DIR/eureka.zip"
LOG_STEP_OUT

LOG_STEP_IN "- Extracting kernel binaries"
rm -f "$WORK_DIR/kernel/"*.img
unzip -q -j "$TMP_DIR/eureka.zip" \
    "eureka/boot.img" "eureka/dtbo.img" "eureka/vendor_boot.img" \
    -d "$WORK_DIR/kernel"
find "$WORK_DIR/kernel" -mindepth 1 -exec "$SRC_DIR/scripts/unsign_bin.sh" {} \;
LOG_STEP_OUT

LOG_STEP_IN "- Deleting stock kernel modules"
DELETE_FROM_WORK_DIR "vendor" "bin/vendor_modprobe.sh"
DELETE_FROM_WORK_DIR "vendor" "lib/modules"
LOG_STEP_OUT

rm -rf "$TMP_DIR"

unset EUREKA_ZIP
