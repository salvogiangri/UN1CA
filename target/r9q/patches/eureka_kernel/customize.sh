EUREKA_R9Q_ZIP="$(curl -s "https://api.github.com/repos/saadelasfur/eureka_releases/releases/latest" \
    | jq -r ".assets[] | .browser_download_url" \
    | grep "Vanilla" | grep "r9q.zip")"

EUREKA_R9Q2_ZIP="$(curl -s "https://api.github.com/repos/saadelasfur/eureka_releases/releases/latest" \
    | jq -r ".assets[] | .browser_download_url" \
    | grep "Vanilla" | grep "r9q2.zip")"

# [
DOWNLOAD_KERNEL_BINARIES()
{
    local KERNEL_ZIP="$1"
    local TARGET="$2"

    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    LOG_STEP_IN "- Downloading $(basename "$KERNEL_ZIP")"
    DOWNLOAD_FILE "$KERNEL_ZIP" "$TMP_DIR/eureka.zip"
    LOG_STEP_OUT

    LOG_STEP_IN "- Extracting kernel binaries"
    unzip -q -j "$TMP_DIR/eureka.zip" \
        "eureka/boot.img" "eureka/dtbo.img" "eureka/vendor_boot.img" \
        -d "$TMP_DIR"

    while IFS= read -r i; do
        local IMAGE="$(basename "$i")"

        if [[ -n "$TARGET" ]]; then
            IMAGE="${IMAGE%.img}_${TARGET}.img"
        else
            "$SRC_DIR/scripts/unsign_bin.sh" "$i"
        fi
        mv "$i" "$WORK_DIR/kernel/$IMAGE"
    done < <(find "$TMP_DIR" -type f -name "*.img")
    LOG_STEP_OUT

    rm -rf "$TMP_DIR"
}
# ]

rm -f "$WORK_DIR/kernel/"*.img

DOWNLOAD_KERNEL_BINARIES "$EUREKA_R9Q_ZIP"
DOWNLOAD_KERNEL_BINARIES "$EUREKA_R9Q2_ZIP" "r9q2"

LOG_STEP_IN "- Deleting stock kernel modules"
DELETE_FROM_WORK_DIR "vendor" "bin/vendor_modprobe.sh"
DELETE_FROM_WORK_DIR "vendor" "lib/modules"
LOG_STEP_OUT

unset EUREKA_R9Q_ZIP EUREKA_R9Q2_ZIP
unset -f DOWNLOAD_KERNEL_BINARIES
