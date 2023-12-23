SKIPUNZIP=1

LINE="$(sed -n '/\/dev\/cpuset\/background\/cpus/=' "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh")"
sed -i \
    "$LINE cecho 0-1 > /dev/cpuset/background/cpus" \
    "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
