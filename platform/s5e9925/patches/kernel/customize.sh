REPO_URL="https://api.github.com/repos/milxnaq/kernel_samsung_universal9925/releases/latest"
REPO_ZIP="$(curl -s "$REPO_URL" | jq -r '.assets[] | select(.name | contains("'"$TARGET_CODENAME"'")) | .browser_download_url')"

LOG_STEP_IN "- Downloading kernel ZIP"

if [[ -d "$TMP_DIR" ]]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi

EVAL "mkdir -p \"$TMP_DIR\""

DOWNLOAD_FILE "$REPO_ZIP" "$TMP_DIR/kernel.zip"

for i in "boot" "dtbo" "vendor_boot"; do
    EVAL "unzip -o -j \"$TMP_DIR/kernel.zip\" \"files/$i.img\" -d \"$WORK_DIR/kernel\""
done

EVAL "rm -rf \"$TMP_DIR\""

LOG_STEP_OUT

unset REPO_URL REPO_ZIP