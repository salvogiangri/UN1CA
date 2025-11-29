LOG "- Replacing every occurrence of 0-5 with 0-7 in /vendor/etc/task_profiles.json"
EVAL "sed -i \"s/0\-5/0\-7/g\" \"$WORK_DIR/vendor/etc/task_profiles.json\""
LOG "- Replacing every occurrence of 6-7 with 0-7 in /vendor/etc/task_profiles.json"
EVAL "sed -i \"s/6\-7/0\-7/g\" \"$WORK_DIR/vendor/etc/task_profiles.json\""
