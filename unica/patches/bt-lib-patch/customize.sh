# [
BUILD_PAYLOAD()
{
    LOG "- Building apex_payload.img"

    "$SRC_DIR/scripts/build_fs_image.sh" "ext4" --no-avb \
        -o "$TMP_DIR/apex_payload.img" -p "system" \
        "$TMP_DIR/apex_payload" "$TMP_DIR/file_context-apex_payload" "$TMP_DIR/fs_config-apex_payload" \
        > /dev/null
    rm -rf "$TMP_DIR/apex_payload" "$TMP_DIR/file_context-apex_payload" "$TMP_DIR/fs_config-apex_payload"
}

EXTRACT_PAYLOAD()
{
    LOG_STEP_IN "- Extracting apex_payload.img from $(basename "$1")"

    EVAL "unzip -j \"$1\" \"apex_payload.img\" -d \"$TMP_DIR\""

    if ! sudo -n -v &> /dev/null; then
        LOG "\033[0;33m! Asking user for sudo password\033[0m"
        if ! sudo -v 2> /dev/null; then
            ABORT "Root permissions are required to unpack APEX image"
        fi
    fi

    LOG_STEP_OUT

    LOG "- Unpacking apex_payload.img"

    mkdir -p "$TMP_DIR/apex_payload"
    mkdir -p "$TMP_DIR/tmp_out"
    EVAL "sudo mount -o ro \"$TMP_DIR/apex_payload.img\" \"$TMP_DIR/tmp_out\""
    EVAL "sudo cp -a -T \"$TMP_DIR/tmp_out\" \"$TMP_DIR/apex_payload\""
    sudo chown -hR "$(whoami):$(whoami)" "$TMP_DIR/apex_payload"
    [ -d "$TMP_DIR/apex_payload/lost+found" ] && rm -rf "$TMP_DIR/apex_payload/lost+found"

    LOG "- Generating fs_config/file_context for apex_payload.img"

    EVAL "sudo find \"$TMP_DIR/tmp_out\" | sudo xargs -I \"{}\" -P \"$(nproc)\" stat -c \"%n %u %g %a capabilities=0x0\" \"{}\" > \"$TMP_DIR/fs_config-apex_payload\""
    EVAL "sudo find \"$TMP_DIR/tmp_out\" | sudo xargs -I \"{}\" -P \"$(nproc)\" sh -c 'echo \"\$1 \$(getfattr -n security.selinux --only-values -h --absolute-names \"\$1\")\"' \"sh\" \"{}\" > \"$TMP_DIR/file_context-apex_payload\""
    sort -o "$TMP_DIR/file_context-apex_payload" "$TMP_DIR/file_context-apex_payload"
    sort -o "$TMP_DIR/fs_config-apex_payload" "$TMP_DIR/fs_config-apex_payload"
    sed -i -e "s|$TMP_DIR/tmp_out |/ |g" -e "s|$TMP_DIR/tmp_out||g" "$TMP_DIR/file_context-apex_payload"
    sed -i -e "s|\.|\\\.|g" -e "s|\+|\\\+|g" -e "s|\[|\\\[|g" \
        -e "s|\]|\\\]|g" -e "s|\*|\\\*|g" "$TMP_DIR/file_context-apex_payload"
    sed -i -e "s|$TMP_DIR/tmp_out | |g" -e "s|$TMP_DIR/tmp_out/||g" "$TMP_DIR/fs_config-apex_payload"

    EVAL "sudo umount \"$TMP_DIR/tmp_out\""
    rm -rf "$TMP_DIR/tmp_out" "$TMP_DIR/apex_payload.img"
}

REPACK_PAYLOAD()
{
    LOG "- Adding apex_payload.img to $(basename "$1")"
    # https://android.googlesource.com/platform/system/apex/+/refs/tags/android-16.0.0_r4/apexer/apexer.py#901
    EVAL "7z a -tzip -mx=0 -mmt=$(nproc) \"$1\" \"$TMP_DIR/apex_payload.img\""
    LOG "- Adding apex_pubkey to $(basename "$1")"
    EVAL "7z a -tzip -mx=0 -mmt=$(nproc) \"$1\" \"$TMP_DIR/apex_pubkey\""
}

SIGN_APEX()
{
    LOG "- Signing $(basename "$1") with platform keys"

    local CERT_PREFIX="aosp"
    if $ROM_IS_OFFICIAL; then
        CERT_PREFIX="unica"
    fi

    # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/apex_utils.py#394
    EVAL "signapk -a 4096 --align-file-size \"$SRC_DIR/security/${CERT_PREFIX}_platform.x509.pem\" \"$SRC_DIR/security/${CERT_PREFIX}_platform.pk8\" \"$1\" \"$(dirname "$1")/temp.apex\""
    mv -f "$(dirname "$1")/temp.apex" "$1"
}

SIGN_PAYLOAD()
{
    LOG "- Signing apex_payload.img with AVB"

    local SALT
    # https://android.googlesource.com/platform/system/apex/+/refs/tags/android-16.0.0_r4/apexer/apexer.py#689
    SALT="$(unzip -p "apex_manifest.pb" "$1" | sha256sum | cut -d " " -f 1)"

    # https://android.googlesource.com/platform/system/apex/+/refs/tags/android-16.0.0_r4/apexer/apexer.py#682
    EVAL "avbtool add_hashtree_footer --do_not_generate_fec --algorithm \"SHA256_RSA4096\" --hash_algorithm \"sha256\" --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\" --prop \"apex.key:com.android.bt\" --salt \"$SALT\" --image \"$TMP_DIR/apex_payload.img\""
    # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/common.py#3775
    EVAL "avbtool extract_public_key --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\" --output \"$TMP_DIR/apex_pubkey\""
}
# ]

if [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
fi
mkdir -p "$TMP_DIR"

EXTRACT_PAYLOAD "$WORK_DIR/system/system/apex/com.android.bt.apex"

# Disable VaultKeeper support
# Before: [tbnz w8, #0, #0xXXXXXX]
# After: [b #0xXXXXXX]
if xxd -p -c 0 "$TMP_DIR/apex_payload/lib64/libbluetooth_jni.so" | grep -q "2897773948050037"; then
    LOG "- Patching \"2897773948050037\" to \"289777392a000014\" in apex_payload/lib64/libbluetooth_jni.so"
    HEX_PATCH "$TMP_DIR/apex_payload/lib64/libbluetooth_jni.so" \
        "2897773948050037" "289777392a000014" > /dev/null
elif xxd -p -c 0 "$TMP_DIR/apex_payload/lib64/libbluetooth_jni.so" | grep -q "2897663948050037"; then
    LOG "- Patching \"2897663948050037\" to \"289766392a000014\" in apex_payload/lib64/libbluetooth_jni.so"
    HEX_PATCH "$TMP_DIR/apex_payload/lib64/libbluetooth_jni.so" \
        "2897663948050037" "289766392a000014" > /dev/null
else
    ABORT "No known patch available for the supplied libbluetooth_jni.so"
fi

BUILD_PAYLOAD
SIGN_PAYLOAD "$WORK_DIR/system/system/apex/com.android.bt.apex"
REPACK_PAYLOAD "$WORK_DIR/system/system/apex/com.android.bt.apex"
SIGN_APEX "$WORK_DIR/system/system/apex/com.android.bt.apex"

rm -rf "$TMP_DIR"

unset -f BUILD_PAYLOAD EXTRACT_PAYLOAD REPACK_PAYLOAD SIGN_APEX SIGN_PAYLOAD
