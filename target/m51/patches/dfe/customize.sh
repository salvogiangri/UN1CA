#!/bin/bash
# Encryption Disabler

VENDOR_ETC="${WORK_DIR}/vendor/etc"

# Atomic fstab patching with specific encryption removal
patch_fstab() {
    local file="$1"
    [ -f "${file}" ] || return 1

    # Specific file encryption removal for userdata line
    LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "${file}")
    sed -i "${LINE}s/,fileencryption=ice//g" "${file}" && chmod 644 "${file}"
}

# Execute patches
echo "Patching encryption configurations..."
patch_fstab "${VENDOR_ETC}/fstab.default"
patch_fstab "${VENDOR_ETC}/fstab.emmc"

echo "Encryption disabled in fstab files"