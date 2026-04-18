# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/build_utils.sh" || return 1

KERNEL_BINS="dt dtbo init_boot vendor_boot"
PARTITIONS_LIST="system vendor product system_ext odm vendor_dlkm odm_dlkm system_dlkm"

_GET_PARTITION_SIZE()
{
    local PARTITION_NAME="$1"

    local PARTITION_SIZE
    PARTITION_SIZE="TARGET_$(tr "[:lower:]" "[:upper:]" <<< "$PARTITION_NAME")_PARTITION_SIZE"
    _CHECK_NON_EMPTY_PARAM "$PARTITION_SIZE" "${!PARTITION_SIZE//none/}" || return 1

    echo -n "${!PARTITION_SIZE}"
}
# ]

# GET_DEVICE_FROM_MOUNTPOINT <mountpoint>
# Returns the device path for the supplied mountpoint.
GET_DEVICE_FROM_MOUNTPOINT()
{
    _CHECK_NON_EMPTY_PARAM "MOUNTPOINT" "$1" || return 1

    local MOUNTPOINT="$1"

    local FSTAB_FILE="$SRC_DIR/target/$TARGET_CODENAME/installer/recovery.fstab"
    if [ ! -f "$FSTAB_FILE" ]; then
        if grep -q "TARGET_PLATFORM=" "$SRC_DIR/target/$TARGET_CODENAME/config.sh"; then
            FSTAB_FILE="$SRC_DIR/platform/"
            FSTAB_FILE+="$(grep "TARGET_PLATFORM=" "$SRC_DIR/target/$TARGET_CODENAME/config.sh" | cut -d "=" -f 2 | sed "s/\"//g")"
            FSTAB_FILE+="/installer/recovery.fstab"
        fi
    fi
    if [ ! -f "$FSTAB_FILE" ]; then
        LOGE "File not found: target/$TARGET_CODENAME/installer/recovery.fstab"
        exit 1
    fi

    if $TARGET_USE_DYNAMIC_PARTITIONS && IS_VALID_PARTITION_NAME "${MOUNTPOINT/\//}"; then
        echo -n "map_partition(\"${MOUNTPOINT/\//}\")"
    else
        local DEVICE
        DEVICE="$(grep -w "$MOUNTPOINT" "$FSTAB_FILE")"
        DEVICE="$(sed "/^#/d" <<< "$DEVICE")"
        DEVICE="$(head -n 1 <<< "$DEVICE")"
        DEVICE="$(cut -f 1 <<< "$DEVICE" | cut -d " " -f 1)"

        if [ ! "$DEVICE" ]; then
            if [[ "$MOUNTPOINT" == "/dt" ]]; then
                GET_DEVICE_FROM_MOUNTPOINT "/dtb"
            elif [[ "$MOUNTPOINT" == "/system" ]]; then
                GET_DEVICE_FROM_MOUNTPOINT "/"
            else
                LOGW "No entry for \"$MOUNTPOINT\" found in target fstab"
                exit 1
            fi
        else
            echo -n "\"$DEVICE\""
        fi
    fi
}

# PRINT_ASSERTIONS <info>
# Returns the assertions code text to be used in the updater-script file.
PRINT_ASSERTIONS()
{
    _CHECK_NON_EMPTY_PARAM "BUILD_INFO" "$1" || return 1

    local BUILD_INFO="$1"

    local DEVICE
    DEVICE="$(grep "^device" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"

    if [ "$(grep "^model" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)" ]; then
        local TARGET_ASSERT_MODEL
        TARGET_ASSERT_MODEL="$(grep "^model" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
        IFS=';' read -r -a TARGET_ASSERT_MODEL <<< "$TARGET_ASSERT_MODEL"

        for i in "${TARGET_ASSERT_MODEL[@]}"; do
            echo -n 'getprop("ro.boot.em.model") == "'
            echo -n "$i"
            echo -n '" || '
        done
        echo -n 'abort("E3004: This package is for \"'
        echo -n "$DEVICE"
        echo    '\" devices; this is a \"" + getprop("ro.product.device") + "\".");'
    else
        echo -n 'getprop("ro.product.device") == "'
        echo -n "$DEVICE"
        echo -n '" || abort("E3004: This package is for \"'
        echo -n "$DEVICE"
        echo    '\" devices; this is a \"" + getprop("ro.product.device") + "\".");'
    fi

    if [ ! -d "$SRC_DIR/target/$DEVICE" ]; then
        LOGE "Folder not found: target/$DEVICE"
        return 1
    fi

    if [ -f "$SRC_DIR/target/$DEVICE/installer/assertions.edify" ]; then
        cat "$SRC_DIR/target/$DEVICE/installer/assertions.edify"
    fi
}

# PRINT_BUILD_INFO <info> [info]
# Returns the text to be used in the build_info.txt file.
# Both source and target info can be passed for incremental zips.
PRINT_BUILD_INFO()
{
    local SOURCE_BUILD_INFO
    local TARGET_BUILD_INFO

    if [[ "$#" == "1" ]]; then
        TARGET_BUILD_INFO="$1"
    elif [[ "$#" == "2" ]]; then
        SOURCE_BUILD_INFO="$1"
        TARGET_BUILD_INFO="$2"
    else
        _CHECK_NON_EMPTY_PARAM "BUILD_INFO" "$1"
        return 1
    fi

    echo -n "device="
    grep "^device" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s
    echo -n "version="
    grep "^version" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s
    echo -n "timestamp="
    grep "^timestamp" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s
    echo -n "security_patch_version="
    grep "^security_patch" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s
    echo -n "incremental="
    if [ "$SOURCE_BUILD_INFO" ]; then
        grep "^timestamp" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s
    else
        echo "0"
    fi
}

# PRINT_HEADER <info>
# Returns the header text to be used in the updater-script file.
PRINT_HEADER()
{
    _CHECK_NON_EMPTY_PARAM "BUILD_INFO" "$1" || return 1

    local BUILD_INFO="$1"

    local ROM_VERSION
    local TARGET_NAME
    local ONEUI_VERSION
    local MAJOR
    local MINOR
    local PATCH
    local SOURCE_FINGERPRINT
    local TARGET_FINGERPRINT

    ROM_VERSION="$(grep "^version" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_NAME="$(grep "^name" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
    ONEUI_VERSION="$(grep "^oneui_version" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
    MAJOR=$(bc -l <<< "scale=0; $ONEUI_VERSION / 10000")
    MINOR=$(bc -l <<< "scale=0; $ONEUI_VERSION % 10000 / 100")
    PATCH=$(bc -l <<< "scale=0; $ONEUI_VERSION % 100")
    if [[ "$PATCH" != "0" ]]; then
        ONEUI_VERSION="$MAJOR.$MINOR.$PATCH"
    else
        ONEUI_VERSION="$MAJOR.$MINOR"
    fi

    SOURCE_FINGERPRINT="$(grep "^source_fingerprint" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
    TARGET_FINGERPRINT="$(grep "^target_fingerprint" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"

    echo    'ui_print(" ");'
    PRINT_SEPARATOR
    echo -n 'ui_print("'
    echo -n "UN1CA $ROM_VERSION for $TARGET_NAME"
    echo    '");'
    echo    'ui_print("Coded by salvo_giangri @XDAforums");'
    PRINT_SEPARATOR
    echo -n 'ui_print("'
    echo -n "One UI version: $ONEUI_VERSION"
    echo    '");'
    echo -n 'ui_print("'
    echo -n "Source: $SOURCE_FINGERPRINT"
    echo    '");'
    echo -n 'ui_print("'
    echo -n "Target: $TARGET_FINGERPRINT"
    echo    '");'
    PRINT_SEPARATOR
}

# PRINT_SEPARATOR
# Returns the separator text to be used in the updater-script file.
PRINT_SEPARATOR()
{
    echo 'ui_print("****************************************");'
}

# SIGN_IMAGE_WITH_AVB <file>
# Signs the supplied image with avbtool if not AVB-signed already.
# The TARGET_${PARTITION_NAME}_PARTITION_SIZE environment variable is required to be set.
SIGN_IMAGE_WITH_AVB()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1" || return 1

    local FILE="$1"

    if ! avbtool info_image --image "$FILE" &> /dev/null; then
        local PARTITION_NAME
        PARTITION_NAME="$(basename "$FILE")"
        PARTITION_NAME="${PARTITION_NAME//.img/}"

        _GET_PARTITION_SIZE "$PARTITION_NAME" > /dev/null || return 1

        local CMD
        CMD+="avbtool add_hash_footer "
        CMD+="--image \"$FILE\" "
        CMD+="--partition_size \"$(_GET_PARTITION_SIZE "$PARTITION_NAME")\" "
        CMD+="--partition_name \"$PARTITION_NAME\" "
        CMD+="--hash_algorithm \"sha256\" "
        CMD+="--algorithm \"SHA256_RSA4096\" "
        CMD+="--key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\""

        LOG "- Signing image with AVB"
        EVAL "$CMD" || return 1
    fi
}
