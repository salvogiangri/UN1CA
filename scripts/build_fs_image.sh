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
source "$SRC_DIR/scripts/utils/build_utils.sh"

FS_TYPE=""
SPARSE=false
INPUT_DIR=""
PARTITION=""
IMAGE_SIZE=""
INODES=""
MOUNT_POINT=""
OUTPUT_FILE=""
FILE_CONTEXT_FILE=""
FS_CONFIG_FILE=""

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#247
CALCULATE_SIZE_AND_RESERVED()
{
    local SIZE="$1"

    # Assume reserved partition size is not set
    if [[ "$FS_TYPE" == "erofs" ]]; then
        SIZE="$(bc -l <<< "scale=0; ($SIZE * 1003) / 1000")"
        [[ "$SIZE" -lt "262144" ]] && SIZE="262144"
    else
        SIZE="$(bc -l <<< "scale=0; ($SIZE * 1.1) / 1")"
        SIZE="$(bc -l <<< "$SIZE + 16777216")"
    fi

    echo "$SIZE"
}

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#266
BUILD_IMAGE_MKFS()
{
    local SPARSE=$SPARSE
    local MANUAL_SPARSE=false

    # Avoid OOM errors when building as sparse image
    if $SPARSE && [[ "$(awk '/MemTotal/ { print int ($2 / 1024) }' "/proc/meminfo")" -lt "10240" ]]; then
        SPARSE=false
        MANUAL_SPARSE=true
    fi

    local BUILD_CMD

    case "$FS_TYPE" in
        "ext4")
            BUILD_CMD+="mkuserimg_mke2fs "
            if $SPARSE; then
                BUILD_CMD+="-s "
            fi
            BUILD_CMD+="\"$INPUT_DIR\" \"$OUTPUT_FILE\" \"ext4\" \"$MOUNT_POINT\" "
            BUILD_CMD+="\"$IMAGE_SIZE\" "
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#808
            BUILD_CMD+="-j \"0\" "
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#49
            BUILD_CMD+="-T \"1230735600\" "
            BUILD_CMD+="-C \"$FS_CONFIG_FILE\" "
            BUILD_CMD+="-L \"$MOUNT_POINT\" "
            if [ "$INODES" ]; then
                BUILD_CMD+="-i \"$INODES\" "
            fi
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#808
            BUILD_CMD+="-M \"0\" "
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#331
            BUILD_CMD+="--inode_size \"256\" "
            BUILD_CMD+="\"$FILE_CONTEXT_FILE\""

            # Avoid build failures if lost+found entry is not in file_context/fs_config
            if ! grep -q -F "lost+found" "$FILE_CONTEXT_FILE"; then
                if [[ "$PARTITION" == "system" ]]; then
                    echo "/lost\+found u:object_r:rootfs:s0" >> "$FILE_CONTEXT_FILE"
                else
                    echo "/$PARTITION/lost\+found $(head -n 1 "$FILE_CONTEXT_FILE" | cut -f 2 -d " ")" >> "$FILE_CONTEXT_FILE"
                fi
            fi

            if ! grep -q -F "lost+found" "$FS_CONFIG_FILE"; then
                if [[ "$PARTITION" == "system" ]]; then
                    echo "lost+found 0 0 700 capabilities=0x0" >> "$FS_CONFIG_FILE"
                else
                    echo "$PARTITION/lost+found 0 0 700 capabilities=0x0" >> "$FS_CONFIG_FILE"
                fi
            fi
            ;;
        "erofs")
            BUILD_CMD+="mkfs.erofs "
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/core/Makefile#2084
            BUILD_CMD+="-z \"lz4hc,9\" "
            BUILD_CMD+="-b \"4096\" "
            BUILD_CMD+="--mount-point \"$MOUNT_POINT\" "
            BUILD_CMD+="--fs-config-file \"$FS_CONFIG_FILE\" "
            BUILD_CMD+="--file-contexts \"$FILE_CONTEXT_FILE\" "
            # Samsung uses a different default fixed timestamp for erofs/f2fs
            BUILD_CMD+="-T \"1640995200\" "
            BUILD_CMD+="\"$OUTPUT_FILE\" \"$INPUT_DIR\""

            # mkfs.erofs has no built-in sparse support
            if $SPARSE; then
                MANUAL_SPARSE=true
            fi
            ;;
        "f2fs")
            BUILD_CMD+="mkf2fsuserimg "
            BUILD_CMD+="\"$OUTPUT_FILE\" \"$IMAGE_SIZE\" "
            if $SPARSE; then
                BUILD_CMD+="-S "
            fi
            BUILD_CMD+="-C \"$FS_CONFIG_FILE\" "
            BUILD_CMD+="-f \"$INPUT_DIR\" "
            BUILD_CMD+="-s \"$FILE_CONTEXT_FILE\" "
            BUILD_CMD+="-t \"$MOUNT_POINT\" "
            # Samsung uses a different default fixed timestamp for erofs/f2fs
            BUILD_CMD+="-T \"1640995200\" "
            BUILD_CMD+="-L \"$MOUNT_POINT\" "
            # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#818
            BUILD_CMD+="--readonly "
            BUILD_CMD+="-b \"4096\""

            # Usual f2fs f***-ups
            if [[ "$PARTITION" != "system" ]] && ! grep -q "^/$PARTITION/$PARTITION " "$FILE_CONTEXT_FILE"; then
                echo "/$PARTITION/$PARTITION $(head -n 1 "$FILE_CONTEXT_FILE" | cut -d " " -f 2)" >> "$FILE_CONTEXT_FILE"
            fi
            ;;
    esac

    EVAL "$BUILD_CMD" || exit 1

    if $MANUAL_SPARSE; then
        EVAL "img2simg \"$OUTPUT_FILE\" \"$OUTPUT_FILE.sparse\"" || exit 1
        mv -f "$OUTPUT_FILE.sparse" "$OUTPUT_FILE"
    fi
}

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#63
GET_DISK_USAGE()
{
    local SIZE
    SIZE="$(du -b -k -s "$1" | cut -f 1)"
    bc -l <<< "$SIZE * 1024"
}

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#77
GET_INODE_USAGE()
{
    local INODES
    local SPARE_INODES

    INODES="$(find "$1" -print | wc -l)"
    SPARE_INODES="$(bc -l <<< "scale=0; ($INODES * 6) / 100")"
    [[ "$SPARE_INODES" -lt "12" ]] && SPARE_INODES="12"

    bc -l <<< "$INODES + $SPARE_INODES"
}

PREPARE_SCRIPT()
{
    if [[ "$#" == 0 ]]; then
        PRINT_USAGE
        exit 1
    fi

    FS_TYPE="$1"
    if [[ "$FS_TYPE" != "ext4" ]] && \
            [[ "$FS_TYPE" != "f2fs" ]] && \
            [[ "$FS_TYPE" != "erofs" ]]; then
        LOGE "Unsupported file system type: $FS_TYPE"
        exit 1
    fi

    shift

    while [[ "$1" == "-"* ]]; do
        if [[ "$1" == "--inodes" ]] || [[ "$1" == "-i" ]]; then
            shift; INODES="$1"
            if ! [[ "$INODES" =~ ^[+-]?[0-9]+$ ]]; then
                LOGE "Inodes number not valid: $INODES"
                exit 1
            elif [[ "$FS_TYPE" != "ext4" ]]; then
                LOGW "Ignore inodes number flag as file system type is $FS_TYPE"
            fi
        elif [[ "$1" == "--output" ]] || [[ "$1" == "-o" ]]; then
            shift; OUTPUT_FILE="$1"
        elif [[ "$1" == "--partition-name" ]] || [[ "$1" == "-p" ]]; then
            shift; PARTITION="$1"
            if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
                LOGE "\"$PARTITION\" is not a valid partition name"
                exit 1
            fi
        elif [[ "$1" == "--partition-size" ]] || [[ "$1" == "-s" ]]; then
            shift; IMAGE_SIZE="$1"
            if ! [[ "$IMAGE_SIZE" =~ ^[+-]?[0-9]+$ ]]; then
                LOGE "Partition size not valid: $IMAGE_SIZE"
                exit 1
            fi
        elif [[ "$1" == "--sparse" ]] || [[ "$1" == "-S" ]]; then
            SPARSE=true
        else
            LOGE "Unknown option: $1"
            exit 1
        fi

        shift
    done

    INPUT_DIR="$1"
    if [ ! "$INPUT_DIR" ]; then
        PRINT_USAGE
        exit 1
    elif [ ! -d "$INPUT_DIR" ]; then
        LOGE "Folder not found: ${INPUT_DIR//$SRC_DIR\//}"
        exit 1
    fi

    shift

    if [ ! "$PARTITION" ]; then
        PARTITION="$(basename "$INPUT_DIR")"
        if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
            LOGE "\"$PARTITION\" is not a valid partition name. please set --partition-name manually"
            exit 1
        fi
    fi

    MOUNT_POINT="$PARTITION"
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#191
    [[ "$PARTITION" == "system" ]] && MOUNT_POINT="/"

    if [ ! "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="$(dirname "$INPUT_DIR")/$PARTITION.img"
    fi

    FILE_CONTEXT_FILE="$1"
    if [ ! "$FILE_CONTEXT_FILE" ]; then
        PRINT_USAGE
        exit 1
    elif [ ! -f "$FILE_CONTEXT_FILE" ]; then
        LOGE "File not found: ${FILE_CONTEXT_FILE//$SRC_DIR\//}"
        exit 1
    fi

    shift

    FS_CONFIG_FILE="$1"
    if [ ! "$FS_CONFIG_FILE" ]; then
        PRINT_USAGE
        exit 1
    elif [ ! -f "$FS_CONFIG_FILE" ]; then
        LOGE "File not found: ${FS_CONFIG_FILE//$SRC_DIR\//}"
        exit 1
    fi
}

PRINT_USAGE()
{
    echo "Usage: build_fs_image <fs> [options] <dir> <file_context> <fs_config>" >&2
    echo " -i, --inodes : (ext4 only) Specify the extfs inodes count" >&2
    echo " -o, --output : Specify the output image path, defaults to the parent input directory" >&2
    echo " -p, --partition-name : Specify the partition name, defaults to the input directory name" >&2
    echo " -s, --partition-size : Specify the partition size, defaults to the smallest possible" >&2
    echo " -S, --sparse : Outputs an Android sparse image" >&2
}

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#334
ROUND_UP_TO_4K()
{
    local ROUNDED
    ROUNDED="$(bc -l <<< "$1 + 4095")"
    ROUNDED="$(bc -l <<< "scale=0; $ROUNDED - ($ROUNDED % 4096)")"
    echo "$ROUNDED"
}
# ]

PREPARE_SCRIPT "$@"

if $SPARSE; then
    LOG_STEP_IN "- Starting build_fs_image for $(basename "$OUTPUT_FILE") ($FS_TYPE+sparse)..."
else
    LOG_STEP_IN "- Starting build_fs_image for $(basename "$OUTPUT_FILE") ($FS_TYPE)..."
fi

if [ ! "$IMAGE_SIZE" ]; then
    LOG_STEP_IN "! Partition size is not set, detecting minimum size"

    if [[ "$FS_TYPE" == "erofs" ]]; then
        SPARSE=false BUILD_IMAGE_MKFS
        IMAGE_SIZE="$(GET_DISK_USAGE "$OUTPUT_FILE")"
        rm -f "$OUTPUT_FILE"
    else
        IMAGE_SIZE="$(GET_DISK_USAGE "$INPUT_DIR")"
    fi

    LOG "- The tree size of $(basename "$OUTPUT_FILE") is $IMAGE_SIZE bytes ($(bc -l <<< "scale=0; $IMAGE_SIZE / 1048576") MB)"

    IMAGE_SIZE="$(CALCULATE_SIZE_AND_RESERVED "$IMAGE_SIZE")"
    IMAGE_SIZE="$(ROUND_UP_TO_4K "$IMAGE_SIZE")"

    if [[ "$FS_TYPE" == "ext4" ]]; then
        if [ ! "$INODES" ]; then
            INODES="$(GET_INODE_USAGE "$INPUT_DIR")"
        fi

        LOG "- First pass based on estimates of $IMAGE_SIZE bytes ($(bc -l <<< "scale=0; $IMAGE_SIZE / 1048576") MB) and $INODES inodes"
        SPARSE=false BUILD_IMAGE_MKFS

        IMAGE_INFO="$(tune2fs -l "$OUTPUT_FILE")"

        rm -f "$OUTPUT_FILE"

        FREE_SIZE="$(grep -w "Free blocks" <<< "$IMAGE_INFO" | tr -d " " | cut -d ":" -f 2)"
        FREE_SIZE="$(bc -l <<< "$FREE_SIZE * 4096")"
        IMAGE_SIZE="$(bc -l <<< "$IMAGE_SIZE - $FREE_SIZE")"
        IMAGE_SIZE="$(bc -l <<< "scale=0; ($IMAGE_SIZE * 1003) / 1000")"
        [[ "$IMAGE_SIZE" -lt "262144" ]] && IMAGE_SIZE="262144"
        IMAGE_SIZE="$(ROUND_UP_TO_4K "$IMAGE_SIZE")"

        INODES="$(grep -w "Inode count" <<< "$IMAGE_INFO" | tr -d " " | cut -d ":" -f 2)"
        FREE_INODES="$(grep -w "Free inodes" <<< "$IMAGE_INFO"| tr -d " " | cut -d ":" -f 2)"
        INODES="$(bc -l <<< "$INODES - $FREE_INODES")"
        SPARE_INODES=$(bc -l <<< "scale=0; ($INODES * 2) / 100")
        [[ "$SPARE_INODES" -lt 1 ]] && SPARE_INODES=1
        INODES="$(bc -l <<< "$INODES + $SPARE_INODES")"

        LOG "- Allocating $INODES inodes for $(basename "$OUTPUT_FILE")"
    elif [[ "$FS_TYPE" == "f2fs" ]]; then
        # HACK f2fs doesn't seems to like images smaller than 22 MB
        [[ "$IMAGE_SIZE" -lt "23068672" ]] && IMAGE_SIZE="23068672"

        LOG "- First pass based on estimate of $IMAGE_SIZE bytes ($(bc -l <<< "scale=0; $IMAGE_SIZE / 1048576") MB)"
        SPARSE=false BUILD_IMAGE_MKFS

        IMAGE_INFO="$(fsck.f2fs -l "$OUTPUT_FILE")"

        rm -f "$OUTPUT_FILE"

        BLOCK_COUNT="$(grep -w "block_count" <<< "$IMAGE_INFO" | tr -d " " | cut -d ":" -f 2)"
        LOG_BLOCKSIZE="$(grep -w "log_blocksize" <<< "$IMAGE_INFO" | tr -d " " | cut -d ":" -f 2)"

        IMAGE_SIZE="$((BLOCK_COUNT << LOG_BLOCKSIZE))"
    fi

    LOG "- Allocating $IMAGE_SIZE bytes ($(bc -l <<< "scale=0; $IMAGE_SIZE / 1048576") MB) for $(basename "$OUTPUT_FILE")"

    LOG_STEP_OUT
fi

LOG "- Building image"
BUILD_IMAGE_MKFS

LOG_STEP_OUT

exit 0
