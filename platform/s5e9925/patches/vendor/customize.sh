if ! grep -q "init_31_0 tee_file" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
    {
        echo "(allow init_31_0 tee_file (dir (mounton)))"
        echo "(allow priv_app_31_0 tee_file (dir (getattr)))"
    } >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
fi