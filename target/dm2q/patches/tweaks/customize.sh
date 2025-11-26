# shellcheck shell=bash
if [ -f "$WORK_DIR/vendor/bin/init.kernel.post_boot-kalama.sh" ]; then
    LOG "- Patching /vendor/bin/init.kernel.post_boot-kalama.sh"
    LINE="$(sed -n "/\/dev\/cpuset\/background\/cpus/=" "$WORK_DIR/vendor/bin/init.kernel.post_boot-kalama.sh" 2> /dev/null)"
    if [ -n "$LINE" ]; then
        sed -i \
            "${LINE}c\\echo 0-1 > /dev/cpuset/background/cpus\\necho 0-3 > /dev/cpuset/restricted/cpus" \
            "$WORK_DIR/vendor/bin/init.kernel.post_boot-kalama.sh" 2> /dev/null
    fi
fi