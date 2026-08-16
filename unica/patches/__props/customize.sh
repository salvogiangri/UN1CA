# Property identifying the UN1CA version
SET_PROP "system" "ro.unica.version" "$ROM_VERSION"
EVAL "echo \"ro.unica.version u:object_r:build_prop:s0 exact string\" >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""

# Property identifying the UN1CA build time
SET_PROP "system" "ro.unica.timestamp" "$ROM_BUILD_TIMESTAMP"
EVAL "echo \"ro.unica.timestamp u:object_r:build_prop:s0 exact string\" >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""

# Property indentifying the device codename UN1CA is being built for
SET_PROP "system" "ro.unica.device" "$TARGET_CODENAME"
EVAL "echo \"ro.unica.device u:object_r:build_prop:s0 exact string\" >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""

# Property identifying the UN1CA build as a whole
# This bundles the properties which aren't already part of Android OS
# unica/<ro.unica.device>:<MAJOR.MINOR.PATCH from ro.unica.version>/<8-digit commit hash from ro.unica.version><.dirty>/<ro.unica.timestamp>:<user/userdebug>/<release/test>-keys

# unica header + the target codename
FINGERPRINT="unica/${TARGET_CODENAME}:"

# version value is UN1CA version
FINGERPRINT+="$(grep -o "^[0-9]\+\.[0-9]\+\.[0-9]\+" <<< "$ROM_VERSION")/"

# build ID value is the UN1CA commit
FINGERPRINT+="$(cut -d"-" -f 2 <<< "$ROM_VERSION")"
# append .dirty if dirty
if grep -q -- "-dirty" <<< "$ROM_VERSION"; then
    FINGERPRINT+=".dirty/"
else
    FINGERPRINT+="/"
fi

# incremental value matching the UN1CA build timestamp
FINGERPRINT+="${ROM_BUILD_TIMESTAMP}:"

# user/userdebug reflecting $DEBUG
if $DEBUG; then
    FINGERPRINT+="userdebug/"
else
    FINGERPRINT+="user/"
fi

# test-keys/release-keys for $ROM_IS_OFFICIAL
if $ROM_IS_OFFICIAL; then
    FINGERPRINT+="release-keys"
else
    FINGERPRINT+="test-keys"
fi

SET_PROP "system" "ro.unica.fingerprint" "$FINGERPRINT"
EVAL "echo \"ro.unica.fingerprint u:object_r:build_prop:s0 exact string\" >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""

unset FINGERPRINT
