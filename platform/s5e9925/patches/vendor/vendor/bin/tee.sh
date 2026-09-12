#!/vendor/bin/sh

# Dynamically select the proper firmware blobs to support both the users on older TEEgris and ones on the newer one.
# We cannot use ro.bootloader as it comes from the old sboot.bin, but we can check in the "radio" (sda17) partition.
# If the string for older TEE isn't matched, a system property will be set which will be used later to
# bind mount the correct TEEgris folder.

if strings /dev/block/sda17 | grep -q FYI3; then
    setprop vendor.teegris.old true
fi