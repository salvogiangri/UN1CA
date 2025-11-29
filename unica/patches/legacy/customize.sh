# [
BACKPORT_SF_PROPS()
{
    local FILE="$WORK_DIR/vendor/build.prop"
    if [ -f "$WORK_DIR/vendor/default.prop" ]; then
        FILE="$WORK_DIR/vendor/default.prop"
    fi

    if [ ! -f "$FILE" ]; then
        ABORT "File not found: ${FILE//$SRC_DIR\//}"
    fi

    local PROP
    local VALUE

    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
        PATCHED=true

        PROP="ro.surface_flinger.enable_frame_rate_override"
        VALUE="$(test "$TARGET_LCD_CONFIG_HFR_MODE" -gt "1" && echo "true" || echo "false")"

        if [ ! "$(GET_PROP "vendor" "$PROP")" ]; then
            LOG "- Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            EVAL "sed -i \"/persist.sys.usb.config/i $PROP=$VALUE\" \"$FILE\""
        fi
    fi

    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
        PATCHED=true

        PROP="ro.surface_flinger.set_display_power_timer_ms"

        if [ "$(GET_PROP "vendor" "$PROP")" ]; then
            SET_PROP "vendor" "$PROP" --delete
        fi

        PROP="ro.surface_flinger.enable_frame_rate_override"
        if [ "$(GET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms")" ]; then
            PROP="ro.surface_flinger.set_idle_timer_ms"
        fi
        VALUE="$(GET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate")"
        if [ ! "$VALUE" ]; then
            VALUE="$(test "$TARGET_LCD_CONFIG_HFR_MODE" -gt "1" && echo "true" || echo "false")"
        fi

        if [[ "$(sed -n "/$PROP/{x;p;d;}; x" "$FILE")" != *"use_content_detection_for_refresh_rate"* ]]; then
            if [ ! "$(GET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate")" ]; then
                LOG "- Adding \"ro.surface_flinger.use_content_detection_for_refresh_rate\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            else
                EVAL "sed -i \"/use_content_detection_for_refresh_rate/d\" \"$FILE\""
            fi
            EVAL "sed -i \"/$PROP/i ro.surface_flinger.use_content_detection_for_refresh_rate=$VALUE\" \"$FILE\""
        fi

        PROP="debug.sf.show_refresh_rate_overlay_render_rate"
        VALUE="true"
        if [ ! "$(GET_PROP "vendor" "$PROP")" ]; then
            LOG "- Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            EVAL "sed -i \"/ro.surface_flinger.use_content_detection_for_refresh_rate/i $PROP=$VALUE\" \"$FILE\""
        fi

        PROP="ro.surface_flinger.game_default_frame_rate_override"
        VALUE="60"
        if [ ! "$(GET_PROP "vendor" "$PROP")" ]; then
            LOG "- Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            EVAL "sed -i \"/debug.sf.show_refresh_rate_overlay_render_rate/a $PROP=$VALUE\" \"$FILE\""
        fi
    fi
}

EXTRACT_KERNEL_IMAGE() {
    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\""
    fi
    EVAL "mkdir -p \"$TMP_DIR\""
    EVAL "cp -a \"$WORK_DIR/kernel/boot.img\" \"$TMP_DIR/boot.img\""

    EVAL "unpack_bootimg --boot_img \"$TMP_DIR/boot.img\" --out \"$TMP_DIR/out\" 2>&1"

    EVAL "rm \"$TMP_DIR/boot.img\""

    if [[ "$(READ_BYTES_AT "$TMP_DIR/out/kernel" "0" "2")" == "8b1f" ]]; then
        EVAL "cat \"$TMP_DIR/out/kernel\" | gzip -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$TMP_DIR/out/kernel\""
    fi
}

EXTRACT_KERNEL_MODULES() {
    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\""
    fi
    EVAL "mkdir -p \"$TMP_DIR\""
    EVAL "cp -a \"$WORK_DIR/kernel/vendor_boot.img\" \"$TMP_DIR/vendor_boot.img\""

    EVAL "unpack_bootimg --boot_img \"$TMP_DIR/vendor_boot.img\" --out \"$TMP_DIR/out\" 2>&1"

    EVAL "rm \"$TMP_DIR/vendor_boot.img\""

    while IFS= read -r f; do
        if [[ "$(READ_BYTES_AT "$f" "0" "4")" == "184c2102" ]]; then
            EVAL "cat \"$f\" | lz4 -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$f\""
        elif [[ "$(READ_BYTES_AT "$f" "0" "2")" == "8b1f" ]]; then
            EVAL "cat \"$f\" | gzip -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$f\""
        fi
    done < <(find "$TMP_DIR/out" -maxdepth 1 -type f -name "vendor_ramdisk*")
}
# ]

PATCHED=false

# Pre-API 34
# - Add ro.surface_flinger.enable_frame_rate_override if missing
#
# Pre-API 35
# - Place ro.surface_flinger.use_content_detection_for_refresh_rate correctly
# - Add debug.sf.show_refresh_rate_overlay_render_rate if missing
# - Add ro.surface_flinger.game_default_frame_rate_override if missing
BACKPORT_SF_PROPS

# Support legacy Face HAL (pre-API 34)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
    if [ ! -f "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.biometrics.face@3.0-service" ]; then
        PATCHED=true
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/face/services.jar/0001-Fallback-to-Face-HIDL-2.0.patch"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/biometrics/sensors/face/hidl/HidlToAidlCallbackConverter.smali" "replaceall" \
            "V3_0" \
            "V2_0" \
            > /dev/null
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/biometrics/sensors/face/hidl/TestHal.smali" "replaceall" \
            "V3_0" \
            "V2_0" \
            > /dev/null
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/biometrics/sensors/face/aidl/SemFaceServiceExImpl\$\$ExternalSyntheticLambda6.smali" "remove"
        LOG "- Removing \"smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace.smali\" from /system/system/framework/services.jar"
        EVAL "rm \"$APKTOOL_DIR/system/framework/services.jar/smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace.smali\""
        LOG "- Removing \"smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace\$Proxy.smali\" from /system/system/framework/services.jar"
        EVAL "rm \"$APKTOOL_DIR/system/framework/services.jar/smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace\\\$Proxy.smali\""
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace\$Stub\$1.smali" "remove"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFaceClientCallback\$Proxy.smali" "remove"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFaceClientCallback.smali" "remove"
    fi
fi

# Support legacy SehLights HAL (pre-API 35)
# - Check for [lsr wD, wS, #0x18] to determine if the newer HAL is already in place
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if [ -f "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.light-service" ] && \
            ! xxd -p -c 4 "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.light-service" | grep -q "1853$"; then
        PATCHED=true
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/lights/services.jar/0001-Backport-legacy-SehLights-HAL-code.patch"
    fi
fi

# Ensure config_num_physical_slots is configured (pre-API 36)
# https://android.googlesource.com/platform/frameworks/opt/telephony/+/42e37234cee15c9f3fcfac0532110abfc8843b99%5E%21/#F0
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    if [ ! "$(GET_PROP "ro.telephony.sim_slots.count")" ] && \
            ! grep -q "ro.telephony.sim_slots.count" "$WORK_DIR/vendor/bin/secril_config_svc" && \
            ! grep -q -r "config_num_physical_slots" "$WORK_DIR/vendor/overlay"; then
        PATCHED=true
        APPLY_PATCH "system" "system/framework/telephony-common.jar" \
            "$MODPATH/ril/telephony-common.jar/0001-Backport-legacy-UiccController-code.patch"
    fi
fi

# Support legacy sdFAT kernel drivers (pre-API 35)
# https://android.googlesource.com/platform/system/vold/+/refs/tags/android-16.0.0_r2/fs/Vfat.cpp#150
# - Check for 'bogus directory:' to determine if newer sdFAT drivers are in place
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    EXTRACT_KERNEL_IMAGE
    if grep -q "SDFAT" "$TMP_DIR/out/kernel" && \
        ! grep -q "bogus directory:" "$TMP_DIR/out/kernel"; then
        PATCHED=true
        # ",time_offset=%d" -> "NUL"
        HEX_PATCH "$WORK_DIR/system/system/bin/vold" "2c74696d655f6f66667365743d2564" "000000000000000000000000000000"
    fi
fi

# Ensure IMAGE_CODEC_SAMSUNG support (pre-API 35)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO")" ] && \
            [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO")" != *"image_codec.samsung"* ]]; then
        PATCHED=true
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO" \
            "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO"),image_codec.samsung.v1"
    fi
fi

# Ensure Knox Matrix support
# - Check if target firmware runs on One UI 5.1.1 or above
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
if [ "$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.build.version.oneui")" -lt "50101" ]; then
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/fabric_crypto"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/fabric_crypto.rc"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/FabricCryptoLib.xml"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kmxservice.xml"
    DELETE_FROM_WORK_DIR "system" "system/etc/vintf/manifest/fabric_crypto_manifest.xml"
    DELETE_FROM_WORK_DIR "system" "system/framework/FabricCryptoLib.jar"
    DELETE_FROM_WORK_DIR "system" "system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-cpp.so"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so"
    DELETE_FROM_WORK_DIR "system" "system/priv-app/KmxService"
fi

# Ensure KSMBD support in kernel
# - 4.19.x and below: unsupported
# - 5.4.x-5.10.x: backport (https://github.com/namjaejeon/ksmbd.git)
# - 5.15.x and above: supported
if [ -f "$WORK_DIR/system/system/priv-app/StorageShare/StorageShare.apk" ]; then
    EXTRACT_KERNEL_IMAGE
    if ! grep -q "ksmbd" "$TMP_DIR/out/kernel"; then
        PATCHED=true
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.addshare"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.adduser"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.control"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.mountd"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.tools"
        DELETE_FROM_WORK_DIR "system" "system/etc/default-permissions/default-permissions-com.samsung.android.hwresourceshare.storage.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/init/ksmbd.rc"
        DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.hwresourceshare.storage.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.hwresourceshare.storage.xml"
        DELETE_FROM_WORK_DIR "system" "system/etc/ksmbd.conf"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/StorageShare"
    fi
fi

# Ensure sbauth support in target firmware
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
if [ -f "$WORK_DIR/system/system/bin/sbauth" ] && \
        [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/bin/sbauth" ]; then
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/sbauth"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/sbauth.rc"
fi

# Ensure PASS support (pre-API 35)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if ! grep -q "sec_pass_data_file" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
        PATCHED=true
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/StorageManagerService.smali" "return" \
            'isPassSupport()Z' 'false'
    fi
fi

# Support legacy usb_notify kernel drivers (pre-API 36)
# https://github.com/salvogiangri/UN1CA/discussions/519
# - Check for 'SKY_DEFAULT' to determine if newer usb_notify drivers are in place
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    VBOOT_MISSING=true
    KERNEL_MISSING=true

    if [ "$TARGET_PRODUCT_SHIPPING_API_LEVEL" -ge "30" ]; then
        # Check for GKI devices
        EXTRACT_KERNEL_MODULES
        find "$TMP_DIR/out/"
        if grep -q "SKY_DEFAULT" "$TMP_DIR/out/vendor_ramdisk"*; then
            VBOOT_MISSING=false
        fi
    fi

    # Check for legacy devices
    EXTRACT_KERNEL_IMAGE
    if grep -q "SKY_DEFAULT" "$TMP_DIR/out/kernel"; then
        KERNEL_MISSING=false
    fi

    if $VBOOT_MISSING && $KERNEL_MISSING; then
        PATCHED=true
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor.smali" "replace" \
            "isFinishLockTimer()Z" \
            "RAINY_RESTRICT_MODE" \
            "2"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor.smali" "replace" \
            "onKeyguardStateChanged(Z)V" \
            "CLOUDY_WORK_MODE" \
            "1"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor\$1.smali" "replace" \
            "onChange(Z)V" \
            "CLOUDY_WORK_MODE" \
            "1"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor\$8.smali" "replace" \
            "handleMessage(Landroid/os/Message;)V" \
            "SUNNY_WORK_MODE" \
            "0"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor\$8.smali" "replace" \
            "handleMessage(Landroid/os/Message;)V" \
            "RAINY_RESTRICT_MODE" \
            "2"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbService\$Lifecycle.smali" "replace" \
            "onBootPhase(I)V" \
            "RAINY_RESTRICT_MODE" \
            "2"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbService\$Lifecycle.smali" "replace" \
            "onBootPhase(I)V" \
            "CLOUDY_WORK_MODE" \
            "1"
    fi

    unset VBOOT_MISSING KERNEL_MISSING
fi

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
fi

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi

unset PATCHED TARGET_FIRMWARE_PATH
unset -f BACKPORT_SF_PROPS EXTRACT_KERNEL_IMAGE EXTRACT_KERNEL_MODULES
