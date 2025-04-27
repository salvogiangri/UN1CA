#!/usr/bin/env bash
#
# Copyright (C) 2025 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# [
source "$SRC_DIR/scripts/utils/firmware_utils.sh"

FORCE=false

FIRMWARES=()
MODEL=""
CSC=""
LATEST_FIRMWARE=""
DOWNLOADED_FIRMWARE=""
BL_TAR=""
AP_TAR=""

TMP_DIR="$(mktemp -d)"

# https://unix.stackexchange.com/a/219188
SUPPORTED_FS="$( (awk '{print $NF}' < "/proc/filesystems" | sed '/^$/d'; ls -1 "/lib/modules/$(uname -r)/kernel/fs") | sort -u)"

GET_IMAGE_FILE_SYSTEM()
{
    # https://android.googlesource.com/platform/external/e2fsprogs/+/refs/tags/android-15.0.0_r1/lib/ext2fs/ext2_fs.h#83
    if [[ "$(READ_BYTES_AT "$1" "1080" "2")" == "ef53" ]]; then
        echo "ext4"
    # https://android.googlesource.com/platform/external/f2fs-tools/+/refs/tags/android-15.0.0_r1/include/f2fs_fs.h#395
    elif [[ "$(READ_BYTES_AT "$1" "1024" "4")" == "f2f52010" ]]; then
        echo "f2fs"
    # https://android.googlesource.com/platform/external/erofs-utils/+/refs/tags/android-15.0.0_r1/include/erofs_fs.h#12
    elif [[ "$(READ_BYTES_AT "$1" "1024" "4")" == "e0f5e1e2" ]]; then
        echo "erofs"
    fi
}

EXTRACT_AVB_BINARIES()
{
    if FILE_EXISTS_IN_TAR "$BL_TAR" "vbmeta.img" || FILE_EXISTS_IN_TAR "$BL_TAR" "vbmeta.img.lz4"; then
        LOG_STEP_IN "- Extracting AVB binaries"

        EXTRACT_FILE_FROM_TAR "$BL_TAR" "vbmeta.img" || exit 1

        [ -f "$FW_DIR/${MODEL}_${CSC}/vbmeta_patched.img" ] && rm -rf "$FW_DIR/${MODEL}_${CSC}/vbmeta_patched.img"
        LOG "- Creating vbmeta_patched.img..."
        EVAL "cp -a \"$FW_DIR/${MODEL}_${CSC}/vbmeta.img\" \"$FW_DIR/${MODEL}_${CSC}/vbmeta_patched.img\"" || exit 1
        # https://android.googlesource.com/platform/system/core/+/refs/tags/android-15.0.0_r1/fastboot/fastboot.cpp#1129
        EVAL "printf \"\x03\" | dd of=\"$FW_DIR/${MODEL}_${CSC}/vbmeta_patched.img\" bs=1 seek=123 count=1 conv=notrunc" || exit 1

        LOG_STEP_OUT
    fi
}

EXTRACT_KERNEL_BINARIES()
{
    local FILES="boot.img dtbo.img init_boot.img vendor_boot.img"

    LOG_STEP_IN "- Extracting kernel binaries"

    for f in $FILES; do
        EXTRACT_FILE_FROM_TAR "$AP_TAR" "$f" || exit 1
    done

    LOG_STEP_OUT
}

EXTRACT_OS_PARTITIONS()
{
    # # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#131
    local FILES="system.img vendor.img product.img system_ext.img odm.img vendor_dlkm.img odm_dlkm.img system_dlkm.img"
    local PARTITION

    LOG_STEP_IN "- Extracting OS partitions"

    if FILE_EXISTS_IN_TAR "$AP_TAR" "super.img" || FILE_EXISTS_IN_TAR "$AP_TAR" "super.img.lz4"; then
        EXTRACT_FILE_FROM_TAR "$AP_TAR" "super.img" || exit 1
        UNSPARSE_IMAGE "$FW_DIR/${MODEL}_${CSC}/super.img" || exit 1

        LOG "- Unpacking super.img..."

        EVAL "lpdump \"$FW_DIR/${MODEL}_${CSC}/super.img\" > \"$FW_DIR/${MODEL}_${CSC}/lpdump.txt\"" || exit 1

        if grep -q "virtual_ab_device" "$FW_DIR/${MODEL}_${CSC}/lpdump.txt"; then
            # In Virtual A/B devices only the A slot is filled
            for f in $FILES; do
                PARTITION="${f%.img}"
                lpunpack -p "${PARTITION}_a" "$FW_DIR/${MODEL}_${CSC}/super.img" "$FW_DIR/${MODEL}_${CSC}" &> /dev/null || continue
                mv -f "$FW_DIR/${MODEL}_${CSC}/${PARTITION}_a.img" "$FW_DIR/${MODEL}_${CSC}/$f"
            done
        else
            EVAL "lpunpack \"$FW_DIR/${MODEL}_${CSC}/super.img\" \"$FW_DIR/${MODEL}_${CSC}\"" || exit 1
        fi

        rm -f "$FW_DIR/${MODEL}_${CSC}/super.img"
    else
        for f in $FILES; do
            EXTRACT_FILE_FROM_TAR "$AP_TAR" "$f" || exit 1
            [ -f "$FW_DIR/${MODEL}_${CSC}/$f" ] || continue
            UNSPARSE_IMAGE "$FW_DIR/${MODEL}_${CSC}/$f" || exit 1
        done
    fi

    for f in $FILES; do
        PARTITION="${f%.img}"

        [ -f "$FW_DIR/${MODEL}_${CSC}/$f" ] || continue

        if ! grep -q -w "$(GET_IMAGE_FILE_SYSTEM "$FW_DIR/${MODEL}_${CSC}/$f")" <<< "$SUPPORTED_FS"; then
            LOGE "$(GET_IMAGE_FILE_SYSTEM "$FW_DIR/${MODEL}_${CSC}/$f") is not supported by your system"
            exit 1
        fi

        if ! sudo -n -v &> /dev/null; then
            LOG "$(tput setaf 3)! Asking user for sudo password$(tput sgr0)"
            if ! sudo -v 2> /dev/null; then
                LOGE "Root permissions are required to unpack OS partitions"
                exit 1
            fi
        fi

        LOG "- Unpacking $(basename "$f")..."

        mkdir -p "$FW_DIR/${MODEL}_${CSC}/$PARTITION"
        sudo umount "$FW_DIR/${MODEL}_${CSC}/$f" &> /dev/null
        EVAL "sudo mount -o ro \"$FW_DIR/${MODEL}_${CSC}/$f\" \"$TMP_DIR\"" || exit 1
        EVAL "sudo cp -a -T \"$TMP_DIR\" \"$FW_DIR/${MODEL}_${CSC}/$PARTITION\"" || exit 1
        sudo find "$FW_DIR/${MODEL}_${CSC}/$PARTITION" -exec chown -h "$(whoami):$(whoami)" {} \;
        [ -d "$FW_DIR/${MODEL}_${CSC}/$PARTITION/lost+found" ] && rm -rf "$FW_DIR/${MODEL}_${CSC}/$PARTITION/lost+found"

        LOG "- Generating fs_config/file_context for $(basename "$f")..."

        # shellcheck disable=SC2024
        sudo find "$TMP_DIR" -exec \
            sh -c 'stat -c "%n %u %g %a capabilities=0x0" "$1"' sh {} \; \
            > "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION"
        # shellcheck disable=SC2024
        sudo find "$TMP_DIR" -exec \
            sh -c 'echo -n "$1 "; getfattr -n security.selinux --only-values -h --absolute-names "$1"; echo ""' sh {} \; \
            > "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"
        # https://source.android.com/docs/core/architecture/partitions/system-as-root
        if [[ "$PARTITION" == "system" ]] && [ -d "$FW_DIR/${MODEL}_${CSC}/system/system" ]; then
            sed -i -e "s|$TMP_DIR |/ |g" -e "s|$TMP_DIR||g" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"
            sed -i -e "s|$TMP_DIR | |g" -e "s|$TMP_DIR/||g" "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION"
        else
            sed -i "s|$TMP_DIR|/$PARTITION|g" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"
            sed -i "s|$TMP_DIR|$PARTITION|g" "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION"
        fi
        sed -i -e "s|\.|\\\.|g" -e "s|\+|\\\+|g" -e "s|\[|\\\[|g" \
            -e "s|\]|\\\]|g" -e "s|\*|\\\*|g" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"

        # TODO a way to determine file capabilities has yet to be found, for now let's set it for the only known files
        if [ -f "$FW_DIR/${MODEL}_${CSC}/fs_config-system" ]; then
            sed -i \
                -e "$(sed -n "/run-as/=" "$FW_DIR/${MODEL}_${CSC}/fs_config-system") s/0x0/0xc0/g" \
                -e "$(sed -n "/simpleperf_app_runner/=" "$FW_DIR/${MODEL}_${CSC}/fs_config-system") s/0x0/0xc0/g" \
                "$FW_DIR/${MODEL}_${CSC}/fs_config-system"
        fi

        EVAL "sudo umount \"$TMP_DIR\"" || exit 1
        rm -f "$FW_DIR/${MODEL}_${CSC}/$f"
    done

    LOG_STEP_OUT
}

PREPARE_SCRIPT()
{
    local EXTRA_FIRMWARES=()
    local IGNORE_SOURCE=false
    local IGNORE_TARGET=false

    while [ "$#" != 0 ]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--ignore-source" ]]; then
            IGNORE_SOURCE=true
        elif [[ "$1" == "--ignore-target" ]]; then
            IGNORE_TARGET=true
        elif [[ "$1" == "-"* ]]; then
            LOGE "Unknown option: $1"
            PRINT_USAGE
            exit 1
        else
            EXTRA_FIRMWARES+=("$1")
        fi

        shift
    done

    if ! $IGNORE_SOURCE; then
        _CHECK_NON_EMPTY_PARAM "SOURCE_FIRMWARE" "$SOURCE_FIRMWARE"
        FIRMWARES+=("$SOURCE_FIRMWARE")
        IFS=':' read -r -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
        if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${SOURCE_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if ! $IGNORE_TARGET; then
        _CHECK_NON_EMPTY_PARAM "TARGET_FIRMWARE" "$TARGET_FIRMWARE"
        FIRMWARES+=("$TARGET_FIRMWARE")
        IFS=':' read -r -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
        if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${TARGET_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if [ "${#EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        FIRMWARES+=("${EXTRA_FIRMWARES[@]}")
    fi
}

PRINT_USAGE()
{
    echo "Usage: extract_fw [options] <firmware>" >&2
    echo " --ignore-source : Skip parsing source firmware flags" >&2
    echo " --ignore-target : Skip parsing target firmware flags" >&2
    echo " -f, --force : Force firmware extract" >&2
}
# ]

PREPARE_SCRIPT "$@"

for i in "${FIRMWARES[@]}"; do
    PARSE_FIRMWARE_STRING "$i" || exit 1

    LATEST_FIRMWARE="$(GET_LATEST_FIRMWARE "$MODEL" "$CSC")"
    if [ ! "$LATEST_FIRMWARE" ]; then
        LOGE "Latest available firmware could not be fetched"
        exit 1
    fi

    LOG_STEP_IN "- Processing $MODEL firmware with $CSC CSC"
    LOG "- Downloaded firmware: $(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"
    LOG "- Extracted firmware: $(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)"
    LOG "- Latest available firmware: $LATEST_FIRMWARE"

    LOG_STEP_IN

    if ! $FORCE; then
        # Skip if firmware has been extracted
        if [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ]; then
            if ! COMPARE_SEC_BUILD_VERSION "$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted")" "$LATEST_FIRMWARE"; then
                if [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ]; then
                    if ! COMPARE_SEC_BUILD_VERSION "$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted")" "$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded")"; then
                        LOG "$(tput setaf 3)! A newer firmware has been downloaded, use --force flag if you want to overwrite it$(tput sgr0)"
                    fi
                else
                    LOG "$(tput setaf 3)! A newer firmware is available for download$(tput sgr0)"
                fi
            else
                LOG "$(tput setaf 3)! This firmware has already been extracted$(tput sgr0)"
            fi

            LOG_STEP_OUT; LOG_STEP_OUT
            continue
        fi
    fi

    # Abort if firmware has not been downloaded
    if [ ! -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ]; then
        LOG "$(tput setaf 1)! The firmware has not been downloaded$(tput sgr0)"
        exit 1
    fi

    [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ] && rm -rf "$FW_DIR/${MODEL}_${CSC}"
    mkdir -p "$FW_DIR/${MODEL}_${CSC}"

    DOWNLOADED_FIRMWARE="$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded")"

    BL_TAR="$(find "$ODIN_DIR/${MODEL}_${CSC}" -name "BL_$(cut -d "/" -f 1 -s <<< "$DOWNLOADED_FIRMWARE")*.md5" | sort -r | head -n 1)"
    AP_TAR="$(find "$ODIN_DIR/${MODEL}_${CSC}" -name "AP_$(cut -d "/" -f 1 -s <<< "$DOWNLOADED_FIRMWARE")*.md5" | sort -r | head -n 1)"

    if [ ! "$BL_TAR" ]; then
        LOG "$(tput setaf 1)! No BL tar found$(tput sgr0)"
        exit 1
    elif [ ! "$AP_TAR" ]; then
        LOG "$(tput setaf 1)! No AP tar found$(tput sgr0)"
        exit 1
    fi

    EXTRACT_KERNEL_BINARIES
    EXTRACT_OS_PARTITIONS
    EXTRACT_AVB_BINARIES

    echo -n "$DOWNLOADED_FIRMWARE" > "$FW_DIR/${MODEL}_${CSC}/.extracted"

    if [ -n "$GITHUB_ACTIONS" ]; then
        rm -rf "$ODIN_DIR/${MODEL}_${CSC}"
    fi

    LOG_STEP_OUT; LOG_STEP_OUT
done

rm -rf "$TMP_DIR"

exit 0
