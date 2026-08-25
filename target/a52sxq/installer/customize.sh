REPOSITORY="https://github.com/UN1CA/proprietary_vendor_samsung_sm7325/releases/download"
TAR_FILE="A528NKSS7GYI1_KOO_OKR/A528NKSS7GYI1_kernel.tar"
FILE_NAME="$(basename "$TAR_FILE")"

LOG "- Downloading $FILE_NAME"
DOWNLOAD_FILE "$REPOSITORY/$TAR_FILE" "$TMP_DIR/$FILE_NAME" || return 1

LOG "- Extracting dtbo.img.lz4"
EVAL "cd \"$TMP_DIR\"; tar -xf \"$FILE_NAME\" \"dtbo.img.lz4\"" || return 1
EVAL "rm -f \"$TMP_DIR/$FILE_NAME\"" || return 1

LOG "- Decompressing dtbo.img.lz4"
EVAL "lz4 -d -f --rm \"$TMP_DIR/dtbo.img.lz4\" \"$TMP_DIR/dtbo.img\"" || return 1

"$SRC_DIR/scripts/unsign_bin.sh" "$TMP_DIR/dtbo.img" || return 1

if ! $TARGET_DISABLE_AVB_SIGNING; then
    LOG "- Signing dtbo.img with AVB"
    EVAL "avbtool add_hash_footer --image \"$TMP_DIR/dtbo.img\" --partition_size \"25165824\" --partition_name \"dtbo\" --hash_algorithm \"sha256\" --algorithm \"SHA256_RSA4096\" --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\"" || return 1
fi

unset REPOSITORY TAR_FILE FILE_NAME
