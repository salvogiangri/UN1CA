SKIPUNZIP=1

ENTRIES="
audiomirroring
fabriccrypto
hal_dsms_default
hal_dsms_service
uwb_regulation_skip_prop
"

if $TARGET_HAS_SYSTEM_EXT; then
    SYSTEM_EXT="system_ext"
else
    SYSTEM_EXT="system/system/system_ext"
fi

for e in $ENTRIES; do
    if ! grep -q "\(type $e\)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
        echo "- $e SELinux entry not supported. Removing"
        sed -i "/$e/d" "$WORK_DIR/$SYSTEM_EXT/etc/selinux/mapping/$TARGET_VNDK_VERSION.0.cil"
    fi
done

if [[ "$TARGET_VNDK_VERSION" -gt 30 ]]; then
    if ! grep -q "\(type proc_compaction_proactiveness\)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
        echo "- proc_compaction_proactiveness SELinux entry not supported. Removing"
        sed -i "/proc_compaction_proactiveness/d" "$WORK_DIR/$SYSTEM_EXT/etc/selinux/mapping/$TARGET_VNDK_VERSION.0.cil"
        sed -i "/genfscon.*proactiveness/d" "$WORK_DIR/system_ext/etc/selinux/system_ext_sepolicy.cil"
    fi
fi

