# [
DECOMPILE()
{
    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        bash "$SRC_DIR/scripts/apktool.sh" d "$1"
    fi
}

GET_FP_SENSOR_TYPE()
{
    if [[ "$1" == *"ultrasonic"* ]]; then
        echo "ultrasonic"
    elif [[ "$1" == *"optical"* ]]; then
        echo "optical"
    else
        echo "capacitance"
    fi
}
# ]

if [[ "$(GET_FP_SENSOR_TYPE "$SOURCE_FP_SENSOR_CONFIG")" != "$(GET_FP_SENSOR_TYPE "$TARGET_FP_SENSOR_CONFIG")" ]]; then
    echo "Applying fingerprint sensor patches"

    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/framework/services.jar"
    DECOMPILE "system/priv-app/SecSettings/SecSettings.apk"

    FTP="
    system/framework/framework.jar/smali_classes2/android/hardware/fingerprint/FingerprintManager.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/bio/fingerprint/SemFingerprintManager.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/bio/fingerprint/SemFingerprintManager\$Characteristics.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/rune/CoreRune.smali
    system/framework/services.jar/smali/com/android/server/biometrics/sensors/fingerprint/FingerprintUtils.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/biometrics/fingerprint/FingerprintSettingsUtils.smali
    "
    for f in $FTP; do
        sed -i "s/$SOURCE_FP_SENSOR_CONFIG/$TARGET_FP_SENSOR_CONFIG/g" "$APKTOOL_DIR/$f"
    done

    # TODO: handle ultrasonic & capacitive fp devices
    if [[ "$(GET_FP_SENSOR_TYPE "$TARGET_FP_SENSOR_CONFIG")" == "optical" ]]; then
        cp -a --preserve=all "$SRC_DIR/unica/patches/product_feature/optical_fod/system/"* "$WORK_DIR/system/system"
    fi
fi

if $SOURCE_HAS_HW_MDNIE; then
    if ! $TARGET_HAS_HW_MDNIE; then
        echo "Applying mDNIe patches"

        DECOMPILE "system/framework/framework.jar"
        DECOMPILE "system/framework/services.jar"

        cd "$APKTOOL_DIR/system/framework/framework.jar"
        PATCH="$SRC_DIR/unica/patches/product_feature/mdnie/framework.jar/0001-Disable-HW-mDNIe.patch"
        OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
        cd - &> /dev/null

        cd "$APKTOOL_DIR/system/framework/services.jar"
        PATCH="$SRC_DIR/unica/patches/product_feature/mdnie/services.jar/0001-Disable-HW-mDNIe.patch"
        OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
        cd - &> /dev/null
    fi
else
    if $TARGET_HAS_HW_MDNIE; then
        # TODO: add HW mDNIe support
        true
    fi
fi
