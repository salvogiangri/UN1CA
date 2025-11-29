if [ -f "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh" ]; then
    LOG "- Patching /vendor/bin/init.kernel.post_boot-yupik.sh"
    LINE="$(sed -n "/\/dev\/cpuset\/background\/cpus/=" "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh" 2> /dev/null)"
    sed -i \
        "$LINE cecho 0-1 > /dev/cpuset/background/cpus\necho 0-3 > /dev/cpuset/restricted/cpus" \
        "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh" 2> /dev/null
fi
