# [
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

ADD_TO_WORK_DIR "a54xnsxx" "system" "system/apex/com.android.bt.apex"

DECODE_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"
EXTRACT_PAYLOAD

# Disable VaultKeeper support
# Before: [tbnz w8, #0, #0xa8ee70]
# After: [b #0xa8ee70]
LOG "- Patching \"2897663948050037\" to \"289766392a000014\" in apex_payload/lib64/libbluetooth_jni.so"
HEX_PATCH "$TMP_DIR/unknown/apex_payload/lib64/libbluetooth_jni.so" \
    "2897663948050037" "289766392a000014" > /dev/null

# Disable VBR AAC A2DP Codec
# Before: [csinc w8, w21, wzr, eq]
# After: [mov w8, #0x1]
LOG "- Patching \"1f000072a8069f1a1f090071\" to \"1f000072280080521f090071\" in apex_payload/lib64/libbluetooth_jni.so"
HEX_PATCH "$TMP_DIR/unknown/apex_payload/lib64/libbluetooth_jni.so" \
    "1f000072a8069f1a1f090071" "1f000072280080521f090071" > /dev/null

BUILD_PAYLOAD
SIGN_PAYLOAD
BUILD_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"
SIGN_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"

rm -rf "$TMP_DIR"

unset -f BUILD_APEX BUILD_PAYLOAD DECODE_APEX \
    EXTRACT_PAYLOAD SIGN_APEX SIGN_PAYLOAD
