#!/usr/bin/env bash
# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/install_utils.sh" || exit 1

TMP_DIR="$OUT_DIR/target/$TARGET_CODENAME/zip"

PRIVATE_KEY_PATH="$SRC_DIR/security/"
PUBLIC_KEY_PATH="$SRC_DIR/security/"
if $ROM_IS_OFFICIAL; then
    PRIVATE_KEY_PATH+="unica_ota"
    PUBLIC_KEY_PATH+="unica_ota"
else
    PRIVATE_KEY_PATH+="aosp_testkey"
    PUBLIC_KEY_PATH+="aosp_testkey"
fi
PRIVATE_KEY_PATH+=".pk8"
PUBLIC_KEY_PATH+=".x509.pem"

trap 'rm -rf "$TMP_DIR"' EXIT INT

CALCULATE_MIN_CACHE_SIZE()
{
    local PRUNE_CACHE_FILES="$1"

    local MAX="0"
    local VAL="0"

    while IFS= read -r f; do
        VAL="$(cat "$f")"
        if [ "$VAL" -gt "$MAX" ]; then
            MAX="$VAL"
        fi
    done < <(find "$TMP_DIR" -maxdepth 1 -type f -name "*.max_stashed_size")

    if $PRUNE_CACHE_FILES || [[ "$MAX" == "0" ]]; then
        find "$TMP_DIR" -maxdepth 1 -type f -name "*.max_stashed_size" -delete &> /dev/null
    fi

    echo -n "$MAX"
}

# https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/common.py#4067
GENERATE_OP_LIST()
{
    local OP_LIST_FILE="$TMP_DIR/dynamic_partitions_op_list"

    local SOURCE_SUPER_GROUP_NAME
    local SOURCE_SUPER_GROUP_SIZE
    local TARGET_SUPER_GROUP_NAME
    local TARGET_SUPER_GROUP_SIZE

    SOURCE_SUPER_GROUP_NAME="$(grep "^super_partition_group" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
    SOURCE_SUPER_GROUP_SIZE="$(grep "^super_${SOURCE_SUPER_GROUP_NAME}_group_size" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_SUPER_GROUP_NAME="$(grep "^super_partition_group" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_SUPER_GROUP_SIZE="$(grep "^super_${TARGET_SUPER_GROUP_NAME}_group_size" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"

    local SOURCE_PARTITION_SIZE=0
    local TARGET_PARTITION_SIZE=0
    local OCCUPIED_SPACE=0

    {
        for p in $PARTITIONS_LIST; do
            if [ -f "$TMP_DIR/source/$p.img" ] && [ ! -f "$TMP_DIR/target/$p.img" ]; then
                echo "remove $p"
            fi
        done
        for p in $PARTITIONS_LIST; do
            if [ -f "$TMP_DIR/source/$p.img" ] && [ -f "$TMP_DIR/target/$p.img" ] && \
                [[ "$SOURCE_SUPER_GROUP_NAME" != "$TARGET_SUPER_GROUP_NAME" ]]; then
                echo "# Move partition $p from $SOURCE_SUPER_GROUP_NAME to default"
                echo "move $p default"
            fi
        done
        for p in $PARTITIONS_LIST; do
            if [ -f "$TMP_DIR/source/$p.img" ] && [ -f "$TMP_DIR/target/$p.img" ]; then
                SOURCE_PARTITION_SIZE="$(GET_IMAGE_SIZE "$TMP_DIR/source/$p.img")"
                TARGET_PARTITION_SIZE="$(GET_IMAGE_SIZE "$TMP_DIR/target/$p.img")"
                if [ "$SOURCE_PARTITION_SIZE" -gt "$TARGET_PARTITION_SIZE" ]; then
                    echo "# Shrink partition $p from $SOURCE_PARTITION_SIZE to $TARGET_PARTITION_SIZE"
                    echo "resize $p $TARGET_PARTITION_SIZE"
                    OCCUPIED_SPACE=$((OCCUPIED_SPACE + TARGET_PARTITION_SIZE))
                fi
            fi
        done
        if [[ "$SOURCE_SUPER_GROUP_NAME" != "$TARGET_SUPER_GROUP_NAME" ]]; then
            echo "remove_group $SOURCE_SUPER_GROUP_NAME"
        fi
        if [[ "$SOURCE_SUPER_GROUP_NAME" == "$TARGET_SUPER_GROUP_NAME" ]] && \
            [ "$SOURCE_SUPER_GROUP_SIZE" -gt "$TARGET_SUPER_GROUP_SIZE" ]; then
            echo "# Shrink group $TARGET_SUPER_GROUP_NAME from $SOURCE_SUPER_GROUP_SIZE to $TARGET_SUPER_GROUP_SIZE"
            echo "resize_group $TARGET_SUPER_GROUP_NAME $TARGET_SUPER_GROUP_SIZE"
        fi
        if [[ "$SOURCE_SUPER_GROUP_NAME" != "$TARGET_SUPER_GROUP_NAME" ]]; then
            echo "# Add group $TARGET_SUPER_GROUP_NAME with maximum size $TARGET_SUPER_GROUP_SIZE"
            echo "add_group $TARGET_SUPER_GROUP_NAME $TARGET_SUPER_GROUP_SIZE"
        fi
        if [[ "$SOURCE_SUPER_GROUP_NAME" == "$TARGET_SUPER_GROUP_NAME" ]] && \
            [ "$SOURCE_SUPER_GROUP_SIZE" -lt "$TARGET_SUPER_GROUP_SIZE" ]; then
            echo "# Grow group $TARGET_SUPER_GROUP_NAME from $SOURCE_SUPER_GROUP_SIZE to $TARGET_SUPER_GROUP_SIZE"
            echo "resize_group $TARGET_SUPER_GROUP_NAME $TARGET_SUPER_GROUP_SIZE"
        fi
        for p in $PARTITIONS_LIST; do
            if [ ! -f "$TMP_DIR/source/$p.img" ] && [ -f "$TMP_DIR/target/$p.img" ]; then
                echo "# Add partition $p to group $TARGET_SUPER_GROUP_NAME"
                echo "add $p $TARGET_SUPER_GROUP_NAME"
            fi
        done
        for p in $PARTITIONS_LIST; do
            if [ ! -f "$TMP_DIR/target/$p.img" ]; then
                continue
            fi
            if [ -f "$TMP_DIR/source/$p.img" ]; then
                SOURCE_PARTITION_SIZE="$(GET_IMAGE_SIZE "$TMP_DIR/source/$p.img")"
            else
                SOURCE_PARTITION_SIZE=0
            fi
            TARGET_PARTITION_SIZE="$(GET_IMAGE_SIZE "$TMP_DIR/target/$p.img")"
            if [ "$SOURCE_PARTITION_SIZE" -lt "$TARGET_PARTITION_SIZE" ]; then
                echo "# Grow partition $p from $SOURCE_PARTITION_SIZE to $TARGET_PARTITION_SIZE"
                echo "resize $p $TARGET_PARTITION_SIZE"
                OCCUPIED_SPACE=$((OCCUPIED_SPACE + TARGET_PARTITION_SIZE))
            fi
        done
        for p in $PARTITIONS_LIST; do
            if [ -f "$TMP_DIR/source/$p.img" ] && [ -f "$TMP_DIR/target/$p.img" ] && \
                [[ "$SOURCE_SUPER_GROUP_NAME" != "$TARGET_SUPER_GROUP_NAME" ]]; then
                echo "# Move partition $p from default to $TARGET_SUPER_GROUP_NAME"
                echo "move $p $TARGET_SUPER_GROUP_NAME"
            fi
        done
    } > "$OP_LIST_FILE"

    for p in $PARTITIONS_LIST; do
        if [ -f "$TMP_DIR/source/$p.img" ] && [ -f "$TMP_DIR/target/$p.img" ]; then
            SOURCE_PARTITION_SIZE="$(GET_IMAGE_SIZE "$TMP_DIR/source/$p.img")"
            TARGET_PARTITION_SIZE="$(GET_IMAGE_SIZE "$TMP_DIR/target/$p.img")"
            if [[ "$SOURCE_PARTITION_SIZE" == "$TARGET_PARTITION_SIZE" ]]; then
                OCCUPIED_SPACE=$((OCCUPIED_SPACE + TARGET_PARTITION_SIZE))
            fi
        fi
    done

    if [ "$OCCUPIED_SPACE" -gt "$TARGET_SUPER_GROUP_SIZE" ]; then
        LOGE "OS size ($OCCUPIED_SPACE) is bigger than the target group size ($TARGET_SUPER_GROUP_SIZE)"
        exit 1
    fi
}

GENERATE_OTA_METADATA()
{
    local PROTO_FILE="$SRC_DIR/external/android-tools/vendor/build/tools/releasetools/ota_metadata.proto"

    local DEVICE
    local RELEASE
    local SOURCE_INCREMENTAL
    local TARGET_INCREMENTAL
    local TIMESTAMP
    local SECURITY_PATCH_LEVEL
    local SOURCE_FINGERPRINT
    local TARGET_FINGERPRINT

    DEVICE="$(grep "^device" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    RELEASE="$(grep "^os_version" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    SOURCE_INCREMENTAL="$(grep "^build_incremental" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_INCREMENTAL="$(grep "^build_incremental" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TIMESTAMP="$(grep "^build_date" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    SECURITY_PATCH_LEVEL="$(grep "^security_patch" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    SOURCE_FINGERPRINT="$(grep "^source_fingerprint" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_FINGERPRINT="$(grep "^source_fingerprint" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"

    mkdir -p "$TMP_DIR/META-INF/com/android"

    # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/ota_utils.py#258
    if [ -f "$PROTO_FILE" ]; then
        local MESSAGE

        MESSAGE+="type: BLOCK"
        MESSAGE+=", precondition: {device: \\\"$DEVICE\\\""
        MESSAGE+=", build: \\\"$SOURCE_FINGERPRINT\\\""
        MESSAGE+=", build_incremental: \\\"$SOURCE_INCREMENTAL\\\"}"
        MESSAGE+=", postcondition: {device: \\\"$DEVICE\\\""
        MESSAGE+=", build: \\\"$TARGET_FINGERPRINT\\\""
        MESSAGE+=", build_incremental: \\\"$TARGET_INCREMENTAL\\\""
        MESSAGE+=", timestamp: $TIMESTAMP"
        MESSAGE+=", sdk_level: \\\"$RELEASE\\\""
        MESSAGE+=", security_patch_level: \\\"$SECURITY_PATCH_LEVEL\\\"}"
        MESSAGE+=", required_cache: $(CALCULATE_MIN_CACHE_SIZE false)"

        EVAL "protoc --encode=build.tools.releasetools.OtaMetadata --proto_path=\"$(dirname "$PROTO_FILE")\" \"$PROTO_FILE\" <<< \"$MESSAGE\" > \"$TMP_DIR/META-INF/com/android/metadata.pb\"" || exit 1
    fi

    # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/ota_utils.py#313
    {
        echo "ota-required-cache=$(CALCULATE_MIN_CACHE_SIZE true)"
        echo "ota-type=BLOCK"
        echo "post-build=$TARGET_FINGERPRINT"
        echo "post-build-incremental=$TARGET_INCREMENTAL"
        echo "post-sdk-level=$RELEASE"
        echo "post-security-patch-level=$SECURITY_PATCH_LEVEL"
        echo "post-timestamp=$TIMESTAMP"
        echo "pre-build=$SOURCE_FINGERPRINT"
        echo "pre-build-incremental=$SOURCE_INCREMENTAL"
        echo "pre-device=$DEVICE"
    } > "$TMP_DIR/META-INF/com/android/metadata"
}

GENERATE_UPDATER_SCRIPT()
{
    local SCRIPT_FILE="$TMP_DIR/META-INF/com/google/android/updater-script"

    local PARTITION_COUNT=0

    [ -f "$TMP_DIR/vendor.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))
    [ -f "$TMP_DIR/product.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))
    [ -f "$TMP_DIR/system_ext.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))
    [ -f "$TMP_DIR/odm.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))
    [ -f "$TMP_DIR/vendor_dlkm.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))
    [ -f "$TMP_DIR/odm_dlkm.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))
    [ -f "$TMP_DIR/system_dlkm.transfer.list" ] && PARTITION_COUNT=$((PARTITION_COUNT + 1))

    {
        PRINT_ASSERTIONS "$TARGET_BUILD_INFO" || exit 1

        PRINT_HEADER "$TARGET_BUILD_INFO" || exit 1

        # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/non_ab_ota.py#397
        echo    'ui_print("Verify partitions...");'
        # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/common.py#3492
        for p in $PARTITIONS_LIST; do
            if [ ! -f "$TMP_DIR/$p.transfer.list" ]; then
                continue
            fi
            if [ ! -f "$TMP_DIR/$p.touched_src_sha1" ]; then
                echo -n 'ui_print("Image '
                echo -n "$p"
                echo    ' will be patched unconditionally.");'
            else
                echo -n "if (range_sha1("
                GET_DEVICE_FROM_MOUNTPOINT "/$p"
                echo -n ', "'
                cat "$TMP_DIR/$p.touched_src_ranges"
                echo -n '") == "'
                cat "$TMP_DIR/$p.touched_src_sha1" && rm -f "$TMP_DIR/$p.touched_src_sha1"
                echo -n '" || block_image_verify('
                GET_DEVICE_FROM_MOUNTPOINT "/$p"
                echo -n ', package_extract_file("'
                echo -n "$p.transfer.list"
                echo -n '"), "'
                echo -n "$p.new.dat"
                echo -n '", "'
                echo -n "$p.patch.dat"
                echo    '")) then'
                echo -n 'ui_print("Verified '
                echo -n "$p image..."
                echo    '");'
                echo    'else'
                echo -n "ifelse (block_image_recover("
                GET_DEVICE_FROM_MOUNTPOINT "/$p"
                echo -n ', "'
                cat "$TMP_DIR/$p.touched_src_ranges" && rm -f "$TMP_DIR/$p.touched_src_ranges"
                echo -n '") && block_image_verify('
                GET_DEVICE_FROM_MOUNTPOINT "/$p"
                echo -n ', package_extract_file("'
                echo -n "$p.transfer.list"
                echo -n '"), "'
                echo -n "$p.new.dat"
                echo -n '", "'
                echo -n "$p.patch.dat"
                echo -n '"), ui_print("'
                echo -n "$p recovered successfully."
                echo -n '"), abort("'
                [[ "$p" == "system" ]] && echo -n "E1004" || echo -n "E2004"
                echo -n ": $p partition fails to recover"
                echo    '"));'
                echo    "endif;"
            fi
        done

        if [ "$(CALCULATE_MIN_CACHE_SIZE false)" -gt "0" ]; then
            # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/edify_generator.py#212
            echo -n "apply_patch_space("
            CALCULATE_MIN_CACHE_SIZE false
            echo -n ") || abort("
            echo    '"E3006: Not enough free space on /cache to apply patches.");'
        fi

        # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/non_ab_ota.py#453
        echo -e "\n# ---- start making changes here ----\n"

        if $TARGET_USE_DYNAMIC_PARTITIONS; then
            # https://android.googlesource.com/platform/build/+/refs/tags/android-16.0.0_r4/tools/releasetools/common.py#4032
            echo -e "\n# --- Start patching dynamic partitions ---\n"
            for p in $PARTITIONS_LIST; do
                if [ ! -f "$TMP_DIR/$p.transfer.list" ]; then
                    continue
                fi
                if grep -q "Shrink partition $p " "$TMP_DIR/dynamic_partitions_op_list"; then
                    echo -e "\n# Patch partition $p\n"
                    echo -n 'ui_print("Patching '
                    echo -n "$p"
                    if [ -s "$TMP_DIR/$p.patch.dat" ]; then
                        echo -n " image after verification."
                    else
                        echo -n " image unconditionally..."
                    fi
                    echo    '");'
                    if [[ "$p" == "system" ]]; then
                        echo -n 'show_progress(0.'
                        echo -n "$(bc -l <<< "9 - $PARTITION_COUNT")"
                        echo    '00000, 0);'
                    else
                        echo    'show_progress(0.100000, 0);'
                    fi
                    echo -n "block_image_update("
                    GET_DEVICE_FROM_MOUNTPOINT "/$p"
                    echo -n ', package_extract_file("'
                    echo -n "$p.transfer.list"
                    echo -n '"), "'
                    echo -n "$p.new.dat"
                    [ -f "$TMP_DIR/$p.new.dat.br" ] && echo -n ".br"
                    echo -n '", "'
                    echo -n "$p.patch.dat"
                    echo    '") ||'
                    echo -n '  abort("'
                    [[ "$p" == "system" ]] && echo -n "E1001" || echo -n "E2001"
                    echo -n ": Failed to update $p image."
                    echo    '");'
                fi
            done
            echo -e "\n# Update dynamic partition metadata\n"
            echo -n 'assert(update_dynamic_partitions(package_extract_file("dynamic_partitions_op_list")'
            if [ -f "$TMP_DIR/unsparse_super_empty.img" ]; then
                # https://github.com/LineageOS/android_build/commit/98549f6893c3a93057e2d4cdd1015a93e9473b16
                # https://github.com/LineageOS/android_bootable_deprecated-ota/commit/e97be4333bd3824b8561c9637e9e6de28bc29da0
                echo -n ', package_extract_file("unsparse_super_empty.img")'
            fi
            echo    '));'
        fi
        for p in $PARTITIONS_LIST; do
            if [ ! -f "$TMP_DIR/$p.transfer.list" ]; then
                continue
            fi
            if ! $TARGET_USE_DYNAMIC_PARTITIONS || ! grep -q "Shrink partition $p " "$TMP_DIR/dynamic_partitions_op_list"; then
                $TARGET_USE_DYNAMIC_PARTITIONS && echo -e "\n# Patch partition $p\n"
                echo -n 'ui_print("Patching '
                echo -n "$p"
                if [ -s "$TMP_DIR/$p.patch.dat" ]; then
                    echo -n " image after verification."
                else
                    echo -n " image unconditionally..."
                fi
                echo    '");'
                if [[ "$p" == "system" ]]; then
                    echo -n 'show_progress(0.'
                    echo -n "$(bc -l <<< "9 - $PARTITION_COUNT")"
                    echo    '00000, 0);'
                else
                    echo    'show_progress(0.100000, 0);'
                fi
                echo -n "block_image_update("
                GET_DEVICE_FROM_MOUNTPOINT "/$p"
                echo -n ', package_extract_file("'
                echo -n "$p.transfer.list"
                echo -n '"), "'
                echo -n "$p.new.dat"
                [ -f "$TMP_DIR/$p.new.dat.br" ] && echo -n ".br"
                echo -n '", "'
                echo -n "$p.patch.dat"
                echo    '") ||'
                echo -n '  abort("'
                [[ "$p" == "system" ]] && echo -n "E1001" || echo -n "E2001"
                echo -n ": Failed to update $p image."
                echo    '");'
            fi
        done
        $TARGET_USE_DYNAMIC_PARTITIONS && echo -e "\n# --- End patching dynamic partitions ---\n"

        for b in $KERNEL_BINS; do
            if [ -f "$TMP_DIR/$b.img" ]; then
                echo -n 'ui_print("Full Patching '
                echo -n "$b.img img..."
                echo    '");'
                echo -n 'package_extract_file("'
                echo -n "$b.img"
                echo -n '", '
                GET_DEVICE_FROM_MOUNTPOINT "/$b"
                echo    ");"
            fi
        done
        if [ -f "$TMP_DIR/boot.img" ]; then
            echo    'ui_print("Installing boot image...");'
            echo -n 'package_extract_file("boot.img", '
            GET_DEVICE_FROM_MOUNTPOINT "/boot"
            echo    ");"
        fi

        if [ -f "$SRC_DIR/target/$TARGET_CODENAME/installer/install-end.edify" ]; then
            cat "$SRC_DIR/target/$TARGET_CODENAME/installer/install-end.edify"
        fi

        echo    'set_progress(1.000000);'

        PRINT_SEPARATOR
        echo    'ui_print(" ");'
    } > "$SCRIPT_FILE"
}

VERIFY_SOURCE_COMPATIBILITY()
{
    local SOURCE_DEVICE
    local SOURCE_SPL
    local TARGET_DEVICE
    local TARGET_SPL

    SOURCE_DEVICE="$(grep "^device" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
    SOURCE_SPL="$(grep "^security_patch" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_DEVICE="$(grep "^device" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_SPL="$(grep "^security_patch" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"

    if [[ "$SOURCE_DEVICE" != "$TARGET_DEVICE" ]]; then
        LOGE "Source device ($SOURCE_DEVICE) does not match target device ($TARGET_DEVICE)"
        exit 1
    fi

    if [ "$(date --date "$SOURCE_SPL" "+%s")" -gt "$(date --date "$TARGET_SPL" "+%s")" ]; then
        LOGE "Target security patch level ($TARGET_SPL) is older than source SPL ($SOURCE_SPL)"
        exit 1
    fi
}
# ]

if [ "$#" != "3" ]; then
    echo "Usage: build_incremental_ota_zip <file> <file> <output>" >&2
    exit 1
fi

SOURCE_ZIP="$1"
TARGET_ZIP="$2"
OUTPUT_FILE="$3"

if ! unzip -l "$SOURCE_ZIP" | grep -q "build_info.txt" || unzip -l "$SOURCE_ZIP" | grep -q "META-INF"; then
    LOGE "File not valid: ${SOURCE_ZIP//$SRC_DIR\//}"
    exit 1
fi

if ! unzip -l "$TARGET_ZIP" | grep -q "build_info.txt" || unzip -l "$TARGET_ZIP" | grep -q "META-INF"; then
    LOGE "File not valid: ${TARGET_ZIP//$SRC_DIR\//}"
    exit 1
fi

[ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/META-INF/com/google/android"
cp -a "$SRC_DIR/prebuilts/bootable/deprecated-ota/updater" "$TMP_DIR/META-INF/com/google/android/update-binary"

LOG "- Extracting source files"
EVAL "unzip -o \"$SOURCE_ZIP\" -d \"$TMP_DIR/source\"" || exit 1

LOG "- Extracting target files"
EVAL "unzip -o \"$TARGET_ZIP\" -d \"$TMP_DIR/target\"" || exit 1

SOURCE_BUILD_INFO="$(cat "$TMP_DIR/source/build_info.txt")"
TARGET_BUILD_INFO="$(cat "$TMP_DIR/target/build_info.txt")"

TARGET_CODENAME="$(grep "^device" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
if [ ! -d "$SRC_DIR/target/$DEVICE" ]; then
    LOGE "Folder not found: target/$DEVICE"
    exit 1
fi

TARGET_USE_DYNAMIC_PARTITIONS="$(grep "^use_dynamic_partitions" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"

VERIFY_SOURCE_COMPATIBILITY

if $TARGET_USE_DYNAMIC_PARTITIONS; then
    LOG "- Generating dynamic_partitions_op_list"
    GENERATE_OP_LIST
fi

for p in $PARTITIONS_LIST; do
    if [ ! -f "$TMP_DIR/target/$p.img" ]; then
        continue
    fi

    if [ -f "$TMP_DIR/source/$p.img" ]; then
        if [[ "$(sha1sum "$TMP_DIR/source/$p.img" | cut -d " " -f 1)" != "$(sha1sum "$TMP_DIR/target/$p.img" | cut -d " " -f 1)" ]]; then
            _CHECK_NON_EMPTY_PARAM "TARGET_CACHE_PARTITION_SIZE" "${TARGET_CACHE_PARTITION_SIZE//none/}" || exit 1
            LOG "- Generating $p.img block diff"
            EVAL "img2sdat -o \"$TMP_DIR\" -c \"$TARGET_CACHE_PARTITION_SIZE\" --src-image \"$TMP_DIR/source/$p.img\" --src-block-map \"$TMP_DIR/source/$p.map\" --tgt-block-map \"$TMP_DIR/target/$p.map\" \"$TMP_DIR/target/$p.img\"" || exit 1
        fi
        rm -f "$TMP_DIR/source/$p.img" "$TMP_DIR/source/$p.map" \
            "$TMP_DIR/target/$p.img" "$TMP_DIR/target/$p.map"
    else
        LOG "- Converting $p.img to $p.new.dat"
        EVAL "img2sdat -o \"$TMP_DIR\" --tgt-block-map \"$TMP_DIR/target/$p.map\" \"$TMP_DIR/target/$p.img\"" || exit 1
        rm -f "$TMP_DIR/target/$p.img" "$TMP_DIR/target/$p.map"

        if ! $DEBUG; then
            LOG "- Compressing $p.new.dat"
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#3585
            EVAL "brotli --quality=6 --output=\"$TMP_DIR/$p.new.dat.br\" \"$TMP_DIR/$p.new.dat\"" || exit 1
            rm -f "$TMP_DIR/$p.new.dat"
        fi
    fi
done

while IFS= read -r f; do
    IMG="$(basename "$f")"
    LOG "- Copying $IMG from target files"
    mv -f "$f" "$TMP_DIR/$IMG"
done < <(find "$TMP_DIR/target" -maxdepth 1 -type f -name "*.img")

while IFS= read -r f; do
    rm -f "$f"
done < <(find "$TMP_DIR/source" -maxdepth 1 -type f -name "*.img")

rm -rf "$TMP_DIR/source" "$TMP_DIR/target"

LOG "- Generating updater-script"
GENERATE_UPDATER_SCRIPT

LOG "- Generating build_info.txt"
PRINT_BUILD_INFO "$SOURCE_BUILD_INFO" "$TARGET_BUILD_INFO" > "$TMP_DIR/build_info.txt" || exit 1

LOG "- Generating OTA metadata"
GENERATE_OTA_METADATA

if [ -d "$SRC_DIR/target/$TARGET_CODENAME/installer/root" ]; then
    LOG "- Copying target custom install files"
    EVAL "cp -a \"$SRC_DIR/target/$TARGET_CODENAME/installer/root/\"* \"$TMP_DIR\"" || exit 1
fi

if [ -f "$SRC_DIR/target/$TARGET_CODENAME/installer/customize.sh" ]; then
    LOG_STEP_IN "- Running target custom install script"
    (
    . "$SRC_DIR/target/$TARGET_CODENAME/installer/customize.sh"
    ) || exit 1
    LOG_STEP_OUT
fi

LOG "- Creating zip"
EVAL "rm -f \"$TMP_DIR/rom.zip\"" || exit 1
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#3601
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#3609
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/ota_utils.py#184
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/ota_utils.py#186
EVAL "cd \"$TMP_DIR\" && 7z a -tzip -mx=0 -mmt=$(nproc) $TMP_DIR/rom.zip -r *.patch.dat -ir!META-INF/com/android/* -i!*.new.dat.br" || exit 1
EVAL "cd \"$TMP_DIR\" && 7z a -tzip -mx=3 -mmt=$(nproc) $TMP_DIR/rom.zip -r * -xr!META-INF/com/android/* -x!*.new.dat.br -x!*.patch.dat -x!rom.zip" || exit 1

if ! $DEBUG || $ROM_IS_OFFICIAL; then
    LOG "- Signing zip"
    EVAL "signapk -w \"$PUBLIC_KEY_PATH\" \"$PRIVATE_KEY_PATH\" \"$TMP_DIR/rom.zip\" \"$OUTPUT_FILE\"" || exit 1
    rm -f "$TMP_DIR/rom.zip"
else
    mv -f "$TMP_DIR/rom.zip" "$OUTPUT_FILE"
fi

exit 0
