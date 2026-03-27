#!/usr/bin/env bash
# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/install_utils.sh" || exit 1

trap 'rm -rf "$TMP_DIR"' EXIT INT

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_super_image.py#72
BUILD_SUPER_EMPTY()
{
    local CMD

    CMD="lpmake"
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_super_image.py#75
    CMD+=" --metadata-size \"65536\""
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/core/config.mk#1033
    CMD+=" --super-name \"super\""
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_super_image.py#85
    CMD+=" --metadata-slots \"2\""
    CMD+=" --device \"super:$TARGET_SUPER_PARTITION_SIZE\""
    CMD+=" --group \"$TARGET_SUPER_GROUP_NAME:$(GET_SUPER_GROUP_SIZE)\""
    if [ -f "$TMP_DIR/system.img" ]; then
        CMD+=" --partition \"system:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/vendor.img" ]; then
        CMD+=" --partition \"vendor:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/product.img" ]; then
        CMD+=" --partition \"product:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/system_ext.img" ]; then
        CMD+=" --partition \"system_ext:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/odm.img" ]; then
        CMD+=" --partition \"odm:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/vendor_dlkm.img" ]; then
        CMD+=" --partition \"vendor_dlkm:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/odm_dlkm.img" ]; then
        CMD+=" --partition \"odm_dlkm:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    if [ -f "$TMP_DIR/system_dlkm.img" ]; then
        CMD+=" --partition \"system_dlkm:readonly:0:$TARGET_SUPER_GROUP_NAME\""
    fi
    CMD+=" --output \"$TMP_DIR/unsparse_super_empty.img\""

    EVAL "$CMD" || exit 1
}

GENERATE_BUILD_INFO()
{
    local BUILD_INFO_FILE="$TMP_DIR/build_info.txt"

    local SOURCE_FIRMWARE_PATH
    local TARGET_FIRMWARE_PATH
    local SOURCE_FINGERPRINT
    local TARGET_FINGERPRINT

    SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
    TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

    SOURCE_FINGERPRINT="$(GET_PROP "$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/build.prop" "ro.system.build.fingerprint")"
    SOURCE_FINGERPRINT="${SOURCE_FINGERPRINT//$(GET_PROP "$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/build.prop" "ro.build.product")/$(GET_PROP "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/build.prop" "ro.product.vendor.device")}"
    TARGET_FINGERPRINT="$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.system.build.fingerprint")"
    TARGET_FINGERPRINT="${TARGET_FINGERPRINT//$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.build.product")/$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/build.prop" "ro.product.vendor.device")}"

    {
        echo -n "device="
        [ "$(GET_PROP "system" "ro.unica.device")" ] && GET_PROP "system" "ro.unica.device" || echo "$TARGET_CODENAME"
        # shellcheck disable=SC2128
        [ "$TARGET_ASSERT_MODEL" ] && echo "model=${TARGET_ASSERT_MODEL//:/;}"
        echo "name=$TARGET_NAME"
        echo -n "version="
        [ "$(GET_PROP "system" "ro.unica.version")" ] && GET_PROP "system" "ro.unica.version" || echo "$ROM_VERSION"
        echo -n "timestamp="
        [ "$(GET_PROP "system" "ro.unica.timestamp")" ] && GET_PROP "system" "ro.unica.timestamp" || echo "$ROM_BUILD_TIMESTAMP"
        echo "os_version=$(GET_PROP "system" "ro.build.version.release")"
        echo "oneui_version=$(GET_PROP "system" "ro.build.version.oneui")"
        echo "build_incremental=$(GET_PROP "system" "ro.build.version.incremental")"
        echo "build_date=$(GET_PROP "system" "ro.build.date.utc")"
        echo "security_patch=$(GET_PROP "system" "ro.build.version.security_patch")"
        echo "source_fingerprint=$SOURCE_FINGERPRINT"
        echo "target_fingerprint=$TARGET_FINGERPRINT"
        echo "use_dynamic_partitions=$TARGET_USE_DYNAMIC_PARTITIONS"
        if $TARGET_USE_DYNAMIC_PARTITIONS; then
            echo "super_partition_size=$TARGET_SUPER_PARTITION_SIZE"
            echo "super_partition_group=$TARGET_SUPER_GROUP_NAME"
            echo "super_${TARGET_SUPER_GROUP_NAME}_group_size=$(GET_SUPER_GROUP_SIZE)"
        fi
    } > "$BUILD_INFO_FILE"
}

GET_SUPER_GROUP_SIZE()
{
    local GROUP_NAME="$TARGET_SUPER_GROUP_NAME"
    GROUP_NAME="$(tr "[:lower:]" "[:upper:]" <<< "$TARGET_SUPER_GROUP_NAME")"

    local VAR="TARGET_${GROUP_NAME}_SIZE"

    _CHECK_NON_EMPTY_PARAM "$VAR" "${!VAR}" || exit 1

    echo "${!VAR}"
}
# ]

if [ "$#" != "1" ]; then
    echo "Usage: create_target_files_zip <output>" >&2
    exit 1
fi

OUTPUT_FILE="$1"

[ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

LOG_STEP_IN "- Building OS partitions"
while IFS= read -r f; do
    PARTITION=$(basename "$f")
    IS_VALID_PARTITION_NAME "$PARTITION" || continue

    if $TARGET_USE_DYNAMIC_PARTITIONS; then
        "$SRC_DIR/scripts/build_fs_image.sh" "$TARGET_OS_FILE_SYSTEM_TYPE" \
            -o "$TMP_DIR/$PARTITION.img" -m -S \
            "$WORK_DIR/$PARTITION" "$WORK_DIR/configs/file_context-$PARTITION" "$WORK_DIR/configs/fs_config-$PARTITION" || exit 1
    else
        _GET_PARTITION_SIZE "$PARTITION" > /dev/null || exit 1

        "$SRC_DIR/scripts/build_fs_image.sh" "$TARGET_OS_FILE_SYSTEM_TYPE" \
            -o "$TMP_DIR/$PARTITION.img" -m -S -s "$(_GET_PARTITION_SIZE "$PARTITION")" \
            "$WORK_DIR/$PARTITION" "$WORK_DIR/configs/file_context-$PARTITION" "$WORK_DIR/configs/fs_config-$PARTITION" || exit 1
    fi
done < <(find "$WORK_DIR" -maxdepth 1 -type d)
LOG_STEP_OUT

if $TARGET_USE_DYNAMIC_PARTITIONS; then
    LOG "- Building unsparse_super_empty.img"
    BUILD_SUPER_EMPTY
fi

if [ -d "$WORK_DIR/kernel" ]; then
    KERNEL_BINS="boot.img dt.img dtbo.img init_boot.img vendor_boot.img"

    for f in $KERNEL_BINS; do
        [ ! -f "$WORK_DIR/kernel/$f" ] && continue

        LOG_STEP_IN "- Copying $f"
        EVAL "cp -a \"$WORK_DIR/kernel/$f\" \"$TMP_DIR/$f\"" || exit 1
        if ! $TARGET_DISABLE_AVB_SIGNING; then
            SIGN_IMAGE_WITH_AVB "$TMP_DIR/$f" || exit 1
        fi
        LOG_STEP_OUT
    done
fi

LOG "- Generating build_info.txt"
GENERATE_BUILD_INFO

LOG "- Creating zip"
rm -f "$OUTPUT_FILE"
EVAL "cd \"$TMP_DIR\" && 7z a -tzip -mx=3 -mmt=$(nproc) -mtc=off -mtm=off \"$OUTPUT_FILE\" -r *" || exit 1

exit 0
