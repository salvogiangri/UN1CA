sed -i "s/ldu_blocklist/unica_blocklist/g" "$WORK_DIR/configs/file_context-system"
sed -i "s/ldu_blocklist/unica_blocklist/g" "$WORK_DIR/configs/fs_config-system"
REMOVE_FROM_WORK_DIR "system" "system/etc/ldu_blocklist.xml"
