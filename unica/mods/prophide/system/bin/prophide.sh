#!/system/bin/sh
# https://android.googlesource.com/platform/external/avb/+/88b13e12a0ebe3c5195dbb5f48ba00ec896d1517

rezetprop -n ro.boot.flash.locked "1"
rezetprop -n ro.boot.vbmeta.avb_version "1.3"
rezetprop -n ro.boot.vbmeta.device_state "locked"
rezetprop -n ro.boot.vbmeta.digest "$(dd if=/dev/block/by-name/vbmeta bs=1 count=VB_SIZE 2> /dev/null | sha256sum -b)"
rezetprop -n ro.boot.vbmeta.hash_alg "sha256"
rezetprop -n ro.boot.vbmeta.invalidate_on_error "yes"
rezetprop -n ro.boot.vbmeta.public_key_digest "$(dd if=/dev/block/by-name/vbmeta bs=1 skip=PK_OFFSET count=PK_SIZE 2> /dev/null | sha256sum -b)"
rezetprop -n ro.boot.vbmeta.size "VB_SIZE"
rezetprop -n ro.boot.warranty_bit "0"
rezetprop -n ro.boot.verifiedbootstate "green"
rezetprop -n ro.boot.veritymode "enforcing"
rezetprop -n ro.vendor.boot.warranty_bit "0"
rezetprop -n ro.vendor.build.security_patch "$(getprop ro.build.version.security_patch)"
