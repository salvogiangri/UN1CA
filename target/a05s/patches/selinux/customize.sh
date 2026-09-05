LOG "- Applying \"$(grep "^Subject:" "$MODPATH/0001-update-vendor-selinux-policy-to-non-JDM-UI-8-req.patch" | sed "s/.*PATCH] //")\" to /vendor/etc/selinux"
EVAL "LC_ALL=C git apply --directory='$WORK_DIR/vendor/etc/selinux' --verbose --unsafe-paths '$MODPATH/0001-update-vendor-selinux-policy-to-non-JDM-UI-8-req.patch'"
