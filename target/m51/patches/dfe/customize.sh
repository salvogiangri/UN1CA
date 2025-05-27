#!/bin/bash
# UN1CA-M51 Encryption Disabler

VENDOR_ETC="${WORK_DIR}/vendor/etc"

# Atomic fstab patching with all encryption types
patch_fstab() {
    local file="$1"
    [ -f "${file}" ] || return 1

    # Comprehensive encryption removal
    sed -i -E '
        s/(,|^)(forceencrypt|fileencryption|fbe|fde|inlinecrypt)=/encryptable=/g;
        s/,((file|metadata)_encryption|keydirectory|fsverity|forcefdeorfbe|avb|verify|support_scfs|quota)=[^[:space:]]+//g;
        s/,,+/,/g; s/,[[:space:]]*$//;
    ' "${file}" && chmod 644 "${file}"
}

# Execute patches
echo "Patching encryption configurations..."
patch_fstab "${VENDOR_ETC}/fstab.default"
patch_fstab "${VENDOR_ETC}/fstab.emmc"

echo "Encryption disabled in fstab files"
