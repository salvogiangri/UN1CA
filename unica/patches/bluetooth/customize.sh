SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"

if [[ "$(sha1sum "$WORK_DIR/system/system/apex/com.android.bt.apex" | cut -d " " -f 1)" != \
        "$(sha1sum "$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/apex/com.android.bt.apex" | cut -d " " -f 1)" ]]; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    unset SOURCE_FIRMWARE_PATH
    return 0
fi

# [
BUILD_APK_IN_APEX()
{
    local INPUT_FILE="$1"
    local OUTPUT_FILE

    if [[ "$INPUT_FILE" == *"javalib"* ]]; then
        OUTPUT_FILE="$WORK_DIR/system/system/framework/$(basename "$INPUT_FILE")"
    else
        OUTPUT_FILE="$WORK_DIR/system/system/${INPUT_FILE/$TMP_DIR\/unknown\/apex_payload\//}"
    fi

    if [ -d "$APKTOOL_DIR/${OUTPUT_FILE//$WORK_DIR\/system\//}" ]; then
        LOG "- Building ${INPUT_FILE//$TMP_DIR\/unknown\//}"
        "$SRC_DIR/scripts/apktool.sh" b "system" "${OUTPUT_FILE//$WORK_DIR\/system\//}" > /dev/null
        if [[ "$OUTPUT_FILE" == *".jar" ]]; then
            LOG "- Zipaligning ${INPUT_FILE//$TMP_DIR\/unknown\//}"
        else
            LOG "- Signing ${INPUT_FILE//$TMP_DIR\/unknown\//}"
        fi

        mv -f "$OUTPUT_FILE" "$INPUT_FILE"

        if [[ "$OUTPUT_FILE" == *".apk" ]]; then
            rm -rf "$(dirname "${APKTOOL_DIR:?}/${OUTPUT_FILE//$WORK_DIR\/system\//}")" "$(dirname "$OUTPUT_FILE")"
        else
            rm -rf "${APKTOOL_DIR:?}/${OUTPUT_FILE//$WORK_DIR\/system\//}" "$OUTPUT_FILE"
        fi
    fi
}

BUILD_APEX()
{
    LOG "- Building ${1//$WORK_DIR/}"

    mkdir -p "$TMP_DIR/build/apk"
    cp -a "$TMP_DIR/original/META-INF" "$TMP_DIR/build/apk/META-INF"

    EVAL "apktool b -j \"$(nproc)\" \"$TMP_DIR\""

    mv -f "$TMP_DIR/dist/$(basename "$1")" "$1"
}

BUILD_PAYLOAD()
{
    LOG "- Building apex_payload.img"

    "$SRC_DIR/scripts/build_fs_image.sh" "ext4" --no-avb \
        -o "$TMP_DIR/unknown/apex_payload.img" -p "system" \
        "$TMP_DIR/unknown/apex_payload" "$TMP_DIR/unknown/file_context-apex_payload" "$TMP_DIR/unknown/fs_config-apex_payload" \
        > /dev/null
    rm -rf "$TMP_DIR/unknown/apex_payload" "$TMP_DIR/unknown/file_context-apex_payload" "$TMP_DIR/unknown/fs_config-apex_payload"
}

DECODE_APEX()
{
    LOG "- Decoding ${1//$WORK_DIR/}"
    EVAL "apktool d -j \"$(nproc)\" -o \"$TMP_DIR\" -r \"$1\""
}

DECODE_APK_IN_APEX()
{
    local INPUT_FILE="$1"
    local OUTPUT_FILE

    if [[ "$INPUT_FILE" == *"javalib"* ]]; then
        OUTPUT_FILE="$WORK_DIR/system/system/framework/$(basename "$INPUT_FILE")"
    else
        mkdir -p "$WORK_DIR/system/system/$(dirname "${INPUT_FILE/$TMP_DIR\/unknown\/apex_payload\//}")"
        OUTPUT_FILE="$WORK_DIR/system/system/${INPUT_FILE/$TMP_DIR\/unknown\/apex_payload\//}"
    fi

    if [ ! -f "$OUTPUT_FILE" ]; then
        mv -f "$INPUT_FILE" "$OUTPUT_FILE"
        LOG "- Decoding ${INPUT_FILE//$TMP_DIR\/unknown\//}"
        DECODE_APK "system" "${OUTPUT_FILE//$WORK_DIR\/system\//}" > /dev/null
    fi
}

EXTRACT_PAYLOAD()
{
    LOG_STEP_IN "- Unpacking apex_payload.img"

    if ! sudo -n -v &> /dev/null; then
        LOG "\033[0;33m! Asking user for sudo password\033[0m"
        if ! sudo -v 2> /dev/null; then
            ABORT "Root permissions are required to unpack APEX image"
        fi
    fi

    LOG_STEP_OUT

    mkdir -p "$TMP_DIR/unknown/apex_payload"
    mkdir -p "$TMP_DIR/tmp_out"
    EVAL "sudo mount -o ro \"$TMP_DIR/unknown/apex_payload.img\" \"$TMP_DIR/tmp_out\""
    EVAL "sudo cp -a -T \"$TMP_DIR/tmp_out\" \"$TMP_DIR/unknown/apex_payload\""
    sudo chown -hR "$(whoami):$(whoami)" "$TMP_DIR/unknown/apex_payload"
    if [ -d "$TMP_DIR/unknown/apex_payload/lost+found" ]; then
        rm -rf "$TMP_DIR/unknown/apex_payload/lost+found"
    fi

    LOG "- Generating fs_config/file_context for apex_payload.img"

    EVAL "sudo find \"$TMP_DIR/tmp_out\" | sudo xargs -I \"{}\" -P \"$(nproc)\" stat -c \"%n %u %g %a capabilities=0x0\" \"{}\" > \"$TMP_DIR/unknown/fs_config-apex_payload\""
    EVAL "sudo find \"$TMP_DIR/tmp_out\" | sudo xargs -I \"{}\" -P \"$(nproc)\" sh -c 'echo \"\$1 \$(getfattr -n security.selinux --only-values -h --absolute-names \"\$1\")\"' \"sh\" \"{}\" > \"$TMP_DIR/unknown/file_context-apex_payload\""
    sort -o "$TMP_DIR/unknown/file_context-apex_payload" "$TMP_DIR/unknown/file_context-apex_payload"
    sort -o "$TMP_DIR/unknown/fs_config-apex_payload" "$TMP_DIR/unknown/fs_config-apex_payload"
    sed -i -e "s|$TMP_DIR/tmp_out |/ |g" -e "s|$TMP_DIR/tmp_out||g" "$TMP_DIR/unknown/file_context-apex_payload"
    sed -i -e "s|\.|\\\.|g" -e "s|\+|\\\+|g" -e "s|\[|\\\[|g" \
        -e "s|\]|\\\]|g" -e "s|\*|\\\*|g" "$TMP_DIR/unknown/file_context-apex_payload"
    sed -i -e "s|$TMP_DIR/tmp_out | |g" -e "s|$TMP_DIR/tmp_out/||g" "$TMP_DIR/unknown/fs_config-apex_payload"

    EVAL "sudo umount \"$TMP_DIR/tmp_out\""
    rm -rf "$TMP_DIR/tmp_out" "$TMP_DIR/unknown/apex_payload.img"
}

LOG_MISSING_PATCHES()
{
    local MESSAGE="Missing SPF patches for condition ($1: [${!1}], $2: [${!2}])"

    if $DEBUG; then
        LOGW "$MESSAGE"
    else
        ABORT "${MESSAGE}. Aborting"
    fi
}

SIGN_APEX()
{
    LOG "- Signing ${1//$WORK_DIR/}"

    local CERT_PREFIX="aosp"
    if $ROM_IS_OFFICIAL; then
        CERT_PREFIX="unica"
    fi

    # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/apex_utils.py#394
    EVAL "signapk -a 4096 --align-file-size \"$SRC_DIR/security/${CERT_PREFIX}_platform.x509.pem\" \"$SRC_DIR/security/${CERT_PREFIX}_platform.pk8\" \"$1\" \"$1.signed\""
    mv -f "$1.signed" "$1"
}

SIGN_PAYLOAD()
{
    LOG "- Signing apex_payload.img with AVB"

    local SALT
    # https://android.googlesource.com/platform/system/apex/+/refs/tags/android-16.0.0_r4/apexer/apexer.py#689
    SALT="$(sha256sum "$TMP_DIR/unknown/apex_manifest.pb" | cut -d " " -f 1)"

    # https://android.googlesource.com/platform/system/apex/+/refs/tags/android-16.0.0_r4/apexer/apexer.py#682
    EVAL "avbtool add_hashtree_footer --do_not_generate_fec --algorithm \"SHA256_RSA4096\" --hash_algorithm \"sha256\" --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\" --prop \"apex.key:com.android.bt\" --salt \"$SALT\" --image \"$TMP_DIR/unknown/apex_payload.img\""
    # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/common.py#3775
    EVAL "avbtool extract_public_key --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\" --output \"$TMP_DIR/unknown/apex_pubkey\""
}
# ]

if [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
fi

DECODE_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"
EXTRACT_PAYLOAD

# SEC_PRODUCT_FEATURE_BLUETOOTH_SUPPORT_A2DPSINK_PROFILE
if $SOURCE_BLUETOOTH_SUPPORT_A2DPSINK_PROFILE; then
    if ! $TARGET_BLUETOOTH_SUPPORT_A2DPSINK_PROFILE; then
        DECODE_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        LOG "- Applying \"Disable SUPPORT_A2DPSINK_PROFILE support\" to apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        APPLY_PATCH "system" "system/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk" \
            "$MODPATH/a2dp_sink/Bluetooth.apk/0001-Disable-SUPPORT_A2DPSINK_PROFILE-support.patch" \
            > /dev/null
        DECODE_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/javalib/framework-bluetooth.jar"
        LOG "- Applying \"Disable SUPPORT_A2DPSINK_PROFILE support\" to apex_payload/javalib/framework-bluetooth.jar"
        APPLY_PATCH "system" "system/framework/framework-bluetooth.jar" \
            "$MODPATH/a2dp_sink/framework-bluetooth.jar/0001-Disable-SUPPORT_A2DPSINK_PROFILE-support.patch" \
            > /dev/null
    fi
else
    if $TARGET_BLUETOOTH_SUPPORT_A2DPSINK_PROFILE; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_BLUETOOTH_SUPPORT_A2DPSINK_PROFILE" "TARGET_BLUETOOTH_SUPPORT_A2DPSINK_PROFILE"
    fi
fi

# SEC_PRODUCT_FEATURE_BLUETOOTH_SUPPORT_A2DP_SBM
if ! $SOURCE_BLUETOOTH_SUPPORT_A2DP_SBM; then
    if $TARGET_BLUETOOTH_SUPPORT_A2DP_SBM; then
        DECODE_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        LOG "- Applying \"Enable SUPPORT_A2DP_SBM support\" to apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        APPLY_PATCH "system" "system/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk" \
            "$MODPATH/sbm/Bluetooth.apk/0001-Enable-SUPPORT_A2DP_SBM-support.patch" \
            > /dev/null
    fi
else
    if ! $TARGET_BLUETOOTH_SUPPORT_A2DP_SBM; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_BLUETOOTH_SUPPORT_A2DP_SBM" "TARGET_BLUETOOTH_SUPPORT_A2DP_SBM"
    fi
fi

# SEC_PRODUCT_FEATURE_BLUETOOTH_SUPPORT_HEAD_SAR_BACKOFF
if ! $SOURCE_BLUETOOTH_SUPPORT_HEAD_SAR_BACKOFF; then
    if $TARGET_BLUETOOTH_SUPPORT_HEAD_SAR_BACKOFF; then
        DECODE_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        LOG "- Applying \"Enable SUPPORT_HEAD_SAR_BACKOFF support\" to apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        APPLY_PATCH "system" "system/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk" \
            "$MODPATH/head_sar/Bluetooth.apk/0001-Enable-SUPPORT_HEAD_SAR_BACKOFF-support.patch" \
            > /dev/null
    fi
else
    if ! $TARGET_BLUETOOTH_SUPPORT_HEAD_SAR_BACKOFF; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_BLUETOOTH_SUPPORT_HEAD_SAR_BACKOFF" "TARGET_BLUETOOTH_SUPPORT_HEAD_SAR_BACKOFF"
    fi
fi

# SEC_PRODUCT_FEATURE_BLUETOOTH_SUPPORT_XLNA_CONTROL
if $SOURCE_BLUETOOTH_SUPPORT_XLNA_CONTROL; then
    if ! $TARGET_BLUETOOTH_SUPPORT_XLNA_CONTROL; then
        DECODE_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        LOG "- Applying \"Disable SUPPORT_XLNA_CONTROL support\" to apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        APPLY_PATCH "system" "system/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk" \
            "$MODPATH/xlna/Bluetooth.apk/0001-Disable-SUPPORT_XLNA_CONTROL-support.patch" \
            > /dev/null
    fi
else
    if $TARGET_BLUETOOTH_SUPPORT_XLNA_CONTROL; then
        DECODE_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        LOG "- Applying \"Enable SUPPORT_XLNA_CONTROL support\" to apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
        APPLY_PATCH "system" "system/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk" \
            "$MODPATH/xlna/Bluetooth.apk/0001-Enable-SUPPORT_XLNA_CONTROL-support.patch" \
            > /dev/null
    fi
fi

# Disable VaultKeeper support
# Before: [tbnz w8, #0, #0xXXXXXX]
# After: [b #0xXXXXXX]
LOG "- Patching \"2897773948050037\" to \"289777392a000014\" in apex_payload/lib64/libbluetooth_jni.so"
HEX_PATCH "$TMP_DIR/unknown/apex_payload/lib64/libbluetooth_jni.so" \
    "2897773948050037" "289777392a000014" > /dev/null

BUILD_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/app/Bluetooth@BP2A.250605.031.A3/Bluetooth.apk"
BUILD_APK_IN_APEX "$TMP_DIR/unknown/apex_payload/javalib/framework-bluetooth.jar"
BUILD_PAYLOAD
SIGN_PAYLOAD
BUILD_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"
SIGN_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"

rm -rf "$TMP_DIR"

unset SOURCE_FIRMWARE_PATH
unset -f BUILD_APK_IN_APEX BUILD_APEX BUILD_PAYLOAD \
    DECODE_APEX DECODE_APK_IN_APEX EXTRACT_PAYLOAD \
    LOG_MISSING_PATCHES SIGN_APEX SIGN_PAYLOAD
