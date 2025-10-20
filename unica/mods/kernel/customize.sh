LOG_STEP_IN "- Processing Custom common kernel by @Edgars-cirulis"

PDR="$(pwd)"
DMXQ="dm1q dm2q dm3q"
KERNEL_URL="https://github.com/voltage-dmxq/edgars-sm8550-kernel/releases/latest/download/DMXQ-KERNEL.ZIP"
BOOT_EDITOR_URL="https://github.com/cfig/Android_boot_image_editor/releases/download/v15_r1/boot_editor_v15_r1.zip"
KERNELSU_MANAGER_APK="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v1.1.1/KernelSU_Next_v1.1.1_12851-release.apk"
REPLACE_KERNEL_BINARIES()
{
    DOWNLOAD_FILE "$KERNEL_URL" "$WORK_DIR/kernel.zip"
    DOWNLOAD_FILE "$BOOT_EDITOR_URL" "$WORK_DIR/kernel/editor.zip"
    unzip -pq "$WORK_DIR/kernel.zip" Image >"$WORK_DIR/kernel/Image"
    cd $WORK_DIR/kernel/
    unzip -q "$WORK_DIR/kernel/editor.zip" -d "$WORK_DIR/kernel/editor"
    mv "$WORK_DIR/kernel/editor/boot_editor_v15_r1" "$WORK_DIR/kernel/booteditor"
    rm -r "$WORK_DIR/kernel/editor"
    rm "$WORK_DIR/kernel/editor.zip"
    rm "$WORK_DIR/kernel.zip"
    mv "$WORK_DIR/kernel/boot.img" "$WORK_DIR/kernel/booteditor/"
    cd "$WORK_DIR/kernel/booteditor/" 
    ./gradlew unpack
    mv ../Image "build/unzip_boot/kernel"
    ./gradlew pack
    mv boot.img.clear ../boot.img
    cd ..
    rm -r booteditor
    cd "$PDR"
}

ADD_MANAGER_APK_TO_PRELOAD()
{
    # https://github.com/tiann/KernelSU/issues/886
    local APK_PATH="system/preload/KernelSU-Next/com.rifsxd.ksunext-mesa==/base.apk"

    echo "Adding KernelSU-Next.apk to preload apps"
    mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
    curl -L -s -o "$WORK_DIR/system/$APK_PATH" -z "$WORK_DIR/system/$APK_PATH" "$KERNELSU_MANAGER_APK"

    sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system" \
        && sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"
    while read -r i; do
        FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
        [ -d "$i" ] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
        [ -f "$i" ] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
    done <<< "$(find "$WORK_DIR/system/system/preload")"

    rm -f "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
    while read -r i; do
        FILE="$(echo "$i" | sed "s.$WORK_DIR/system..")"
        echo "$FILE" >> "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
    done <<< "$(find "$WORK_DIR/system/system/preload" -name "*.apk" | sort)"
}

if grep -q -w "$TARGET_CODENAME" <<< "$DMXQ" ; then
    LOG "- Device is a dmxq, adding custom kernel"
    REPLACE_KERNEL_BINARIES
    ADD_MANAGER_APK_TO_PRELOAD    
else
    LOGW "\"$TARGET_CODENAME\" is not a dmxq, Skipping..."
fi
unset PDR DMXQ KERNEL_URL BOOT_EDITOR_URL
