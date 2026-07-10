# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

LOG "- Downloading A528NKSS7GYI1_kernel.tar"
DOWNLOAD_FILE \
    "https://github.com/UN1CA/proprietary_vendor_samsung_sm7325/releases/download/A528NKSS7GYI1_KOO_OKR/A528NKSS7GYI1_kernel.tar" \
    "$TMP_DIR/A528NKSS7GYI1_kernel.tar" || return 1

LOG "- Extracting dtbo.img.lz4"
EVAL "cd \"$TMP_DIR\"; tar -xf \"A528NKSS7GYI1_kernel.tar\" \"dtbo.img.lz4\"" || return 1
EVAL "rm -f \"$TMP_DIR/A528NKSS7GYI1_kernel.tar\"" || return 1

LOG "- Decompressing dtbo.img.lz4"
EVAL "lz4 -d -f --rm \"$TMP_DIR/dtbo.img.lz4\" \"$TMP_DIR/dtbo.img\"" || return 1

"$SRC_DIR/scripts/unsign_bin.sh" "$TMP_DIR/dtbo.img" || return 1

if ! $TARGET_DISABLE_AVB_SIGNING; then
    LOG "- Signing dtbo.img with AVB"
    EVAL "avbtool add_hash_footer --image \"$TMP_DIR/dtbo.img\" --partition_size \"25165824\" --partition_name \"dtbo\" --hash_algorithm \"sha256\" --algorithm \"SHA256_RSA4096\" --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\"" || return 1
fi

LOG_STEP_IN "- Applying Bluetooth In-Call Audio Fix"
if [ -f "$TARGET_DIR/installer/audio_policy_configuration_fixed.xml" ]; then
    LOG "- Overriding system audio policy with working A52s legacy configuration"
    sudo cp -f "$TARGET_DIR/installer/audio_policy_configuration_fixed.xml" "$WORK_DIR/system/system/etc/audio_policy_configuration.xml"
    sudo chmod 644 "$WORK_DIR/system/system/etc/audio_policy_configuration.xml"
else
    LOG "! Fixed audio policy file not found at $TARGET_DIR/installer/"
fi
LOG_STEP_OUT
