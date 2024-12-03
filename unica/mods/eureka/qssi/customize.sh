# [
REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Calm/ACH_The_Voyage.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Calm/ACH_The_Voyage_acoustic.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Calm/ACH_The_Voyage_epic.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Fun/ACH_The_Voyage_EDM.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Fun/ACH_The_Voyage_RnB.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Fun/ACH_The_Voyage_jazz_piano.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Galaxy/ACH_Over_the_Horizon.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Retro/ACH_The_Voyage_pop_remix.ogg"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/media/audio/ringtones/SoundTheme/Retro/ACH_The_Voyage_smooth_remix.ogg"

if ! grep -q "EnvironmentAdaptiveDisplay" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.sead\.xml u:object_r:system_file:s0"
        echo "/system/etc/permissions/privapp-permissions-com\.samsung\.android\.wallpaper\.live\.xml u:object_r:system_file:s0"
        echo "/system/media/audio/ringtones/SoundTheme/Galaxy/ACH_Over_the_Horizon_2024\.ogg u:object_r:system_file:s0"
        echo "/system/priv-app/EnvironmentAdaptiveDisplay u:object_r:system_file:s0"
        echo "/system/priv-app/EnvironmentAdaptiveDisplay/EnvironmentAdaptiveDisplay\.apk u:object_r:system_file:s0"
        echo "/system/priv-app/SpriteWallpaper u:object_r:system_file:s0"
        echo "/system/priv-app/SpriteWallpaper/SpriteWallpaper\.apk u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "EnvironmentAdaptiveDisplay" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/etc/permissions/privapp-permissions-com.samsung.android.sead.xml 0 0 644 capabilities=0x0"
        echo "system/etc/permissions/privapp-permissions-com.samsung.android.wallpaper.live.xml 0 0 644 capabilities=0x0"
        echo "system/media/audio/ringtones/SoundTheme/Galaxy/ACH_Over_the_Horizon_2024.ogg 0 0 644 capabilities=0x0"
        echo "system/priv-app/EnvironmentAdaptiveDisplay 0 0 755 capabilities=0x0"
        echo "system/priv-app/EnvironmentAdaptiveDisplay/EnvironmentAdaptiveDisplay.apk 0 0 644 capabilities=0x0"
        echo "system/priv-app/SpriteWallpaper 0 0 755 capabilities=0x0"
        echo "system/priv-app/SpriteWallpaper/SpriteWallpaper.apk 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
