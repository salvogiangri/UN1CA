LINE="$(sed -n '/\/dev\/cpuset\/background\/cpus/=' "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh")"
sed -i \
    "$LINE cecho 0-1 > /dev/cpuset/background/cpus\necho 0-3 > /dev/cpuset/restricted/cpus" \
    "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
