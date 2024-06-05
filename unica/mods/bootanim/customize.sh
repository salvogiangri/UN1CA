if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/media/audio/ui/PowerOn\.ogg u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "system/media/audio/ui/Power" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/media/audio/ui/PowerOn.ogg 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
