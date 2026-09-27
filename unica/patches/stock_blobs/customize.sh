# [
MATCH_TARGET_AUDIO_FX_LIB()
{
    local WRAPPER="$1"
    local PATTERN="$2"
    local SOURCE_LIB
    local TARGET_LIB

    for d in "lib" "lib64"; do
        SOURCE_LIB="$(find "$WORK_DIR/system/system/$d" -maxdepth 1 -name "$PATTERN" -printf "%f\n")"
        TARGET_LIB="$(find "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/$d" -maxdepth 1 -name "$PATTERN" -printf "%f\n")"

        if [[ "$SOURCE_LIB" == "$TARGET_LIB" ]]; then
            continue
        fi

        if [ "$SOURCE_LIB" ]; then
            DELETE_FROM_WORK_DIR "system" "system/$d/$SOURCE_LIB"
        fi
        if [ "$TARGET_LIB" ]; then
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/$d/$TARGET_LIB" 0 0 644 "u:object_r:system_lib_file:s0"
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/$d/$WRAPPER" 0 0 644 "u:object_r:system_lib_file:s0"
        else
            DELETE_FROM_WORK_DIR "system" "system/$d/$WRAPPER"
        fi
    done
}

MATCH_TARGET_FEATURES()
{
    local SOURCE_FEATURES
    local TARGET_FEATURES

    SOURCE_FEATURES="$(find "$WORK_DIR/system/system/etc/permissions" -name "com.sec.feature*" -printf "%f\n")"
    SOURCE_FEATURES="$(sort <<< "$SOURCE_FEATURES")"
    TARGET_FEATURES="$(find "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/permissions" -name "com.sec.feature*" -printf "%f\n")"
    TARGET_FEATURES="$(sort <<< "$TARGET_FEATURES")"

    for f in $SOURCE_FEATURES; do
        if ! grep -q "$f" <<< "$TARGET_FEATURES"; then
            DELETE_FROM_WORK_DIR "system" "system/etc/permissions/$f"
        fi
    done
    for f in $TARGET_FEATURES; do
        if ! grep -q "$f" <<< "$SOURCE_FEATURES"; then
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/$f" 0 0 644 "u:object_r:system_file:s0"
        fi
    done
}
# ]

TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

MATCH_TARGET_FEATURES

if [ -d "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/saiv" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
        "system/etc/saiv/image_understanding/db/aic_classifier/aic_classifier_cnn.info" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
        "system/etc/saiv/image_understanding/db/aic_detector/aic_detector_cnn.info" 0 0 644 "u:object_r:system_file:s0"
else
    if [ -d "$WORK_DIR/system/system/etc/saiv" ]; then
        DELETE_FROM_WORK_DIR "system" "system/etc/saiv"
    fi
fi

if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/COSPatchScript" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/COSPatchScript" 0 0 644 "u:object_r:system_file:s0"
else
    if [ -f "$WORK_DIR/system/system/etc/COSPatchScript" ]; then
        DELETE_FROM_WORK_DIR "system" "system/etc/COSPatchScript"
    fi
fi

# TODO add APE/DSD extractor libs if required
if [ -f "$WORK_DIR/system/system/lib64/extractors/libsapeextractor.so" ] && \
        [ ! "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_SUPPORT_APE_FORMAT")" ]; then
    DELETE_FROM_WORK_DIR "system" "system/lib64/extractors/libsapeextractor.so"
fi
if [ -f "$WORK_DIR/system/system/lib64/extractors/libsdffextractor.so" ] && \
        [ ! "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_SUPPORT_DSD_FORMAT")" ]; then
    DELETE_FROM_WORK_DIR "system" "system/lib64/extractors/libsdffextractor.so"
fi
if [ -f "$WORK_DIR/system/system/lib64/extractors/libsdsfextractor.so" ] && \
        [ ! "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_SUPPORT_DSD_FORMAT")" ]; then
    DELETE_FROM_WORK_DIR "system" "system/lib64/extractors/libsdsfextractor.so"
fi

MATCH_TARGET_AUDIO_FX_LIB "libaudiosaplus_sec_legacy.so" "lib_SoundAlive_play_plus_ver*.so"
MATCH_TARGET_AUDIO_FX_LIB "libsamsungSoundbooster_plus_legacy.so" "lib_SoundBooster_ver*.so"
for d in "lib" "lib64"; do
    if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/$d/libmysound_legacy.so" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/$d/libmysound_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
    elif [ -f "$WORK_DIR/system/system/$d/libmysound_legacy.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/$d/libmysound_legacy.so"
    fi
done

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/media/bootsamsung.qmg" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/media/bootsamsungloop.qmg" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/media/shutdown.qmg" 0 0 644 "u:object_r:system_file:s0"

if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/priv-app/SohService/SohService.apk" ]; then
    DECODE_APK "system" "system/priv-app/SohService/SohService.apk"

    LOG "- Adding target BSOH blobs"
    EVAL "rm -r \"$APKTOOL_DIR/system/priv-app/SohService/SohService.apk/assets\""
    EVAL "unzip -q \"$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/priv-app/SohService/SohService.apk\" \"assets/*\" -d \"$APKTOOL_DIR/system/priv-app/SohService/SohService.apk\""
else
    if [ -f "$WORK_DIR/system/system/priv-app/SohService/SohService.apk" ]; then
        DELETE_FROM_WORK_DIR "system" "system/priv-app/SohService"
    fi
fi

if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/usr/share/alsa/alsa.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/usr/share/alsa/alsa.conf" 0 0 644 "u:object_r:system_file:s0"
else
    if [ -d "$WORK_DIR/system/system/usr/share/alsa" ]; then
        DELETE_FROM_WORK_DIR "system" "system/usr/share/alsa"
    fi
fi

unset TARGET_FIRMWARE_PATH
unset -f MATCH_TARGET_AUDIO_FX_LIB MATCH_TARGET_FEATURES
