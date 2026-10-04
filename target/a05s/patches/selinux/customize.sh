LOG "- Applying \"$(grep "^Subject:" "$MODPATH/0001-Update-vendor-SEPolicy-for-One-UI-8.patch" | sed "s/.*PATCH] //")\" to /vendor/etc/selinux"
EVAL "LC_ALL=C git apply --directory='$WORK_DIR/vendor/etc/selinux' --verbose --unsafe-paths '$MODPATH/0001-Update-vendor-SEPolicy-for-One-UI-8.patch'"
