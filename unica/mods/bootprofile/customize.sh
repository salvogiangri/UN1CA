# How to capture on device (needs root, ART's profman is on the device):
#   1. resetprop dalvik.vm.profilebootclasspath true
#      resetprop dalvik.vm.profilesystemserver true    (from post-fs-data, then reboot)
#   2. Use the device normally for a few days.
#   3. Keep only the boot format profiles ("pro\0 016\0" magic) from
#      /data/misc/profiles/{cur/0,ref}/*/primary.prof
#   4. profman --generate-boot-image-profile --profile-file=<each> \
#        --apk=<each BOOTCLASSPATH jar> --dex-location=<same> \
#        --out-profile-path=boot-image-profile.txt \
#        --out-preloaded-classes-path=preloaded-classes
#   5. profman --output-profile-type=boot --create-profile-from=boot-image-profile.txt \
#        --apk=<each BOOTCLASSPATH jar> --dex-location=<same> \
#        --reference-profile-file=boot-image.prof
#      (--output-profile-type=bprof for the .bprof variant)

BOOTPROFILE_SRC="$SRC_DIR/target/$TARGET_CODENAME/bootprofile"

ADD_BOOT_PROFILE()
{
    local NAME="$1"

    if [ ! -f "$BOOTPROFILE_SRC/$NAME" ]; then
        LOGW "No $NAME in ${BOOTPROFILE_SRC//$SRC_DIR\//}. Skipping"
        return 0
    fi

    EVAL "cp -a \"$BOOTPROFILE_SRC/$NAME\" \"$WORK_DIR/system/system/etc/$NAME\""

    local ENTRY="system/etc/$NAME"
    if ! grep -q -F "$ENTRY " "$WORK_DIR/configs/fs_config-system" 2> /dev/null; then
        echo "$ENTRY 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    fi
    if ! grep -q -F "/$ENTRY " "$WORK_DIR/configs/file_context-system" 2> /dev/null; then
        echo "/$ENTRY u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
    fi
}
LOG_STEP_IN "- Add boot image profile"
ADD_BOOT_PROFILE "boot-image.prof"
ADD_BOOT_PROFILE "boot-image.bprof"
LOG_STEP_OUT

unset BOOTPROFILE_SRC
unset -f ADD_BOOT_PROFILE
