# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/common_utils.sh"
# ]

# GET_DISK_USAGE <file>
# Returns the size in bytes of the supplied file.
GET_DISK_USAGE()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1" || return 1

    local FILE="$1"

    if [ ! -e "$FILE" ]; then
        LOGE "File not found: ${FILE//$SRC_DIR\//}"
        return 1
    fi

    local SIZE
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/build_image.py#63
    SIZE="$(du -b -k -s "$FILE" | cut -f 1)"

    bc -l <<< "$SIZE * 1024"
}

# GET_IMAGE_SIZE <file>
# Returns the size in bytes of the supplied image.
GET_IMAGE_SIZE()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1" || return 1

    local FILE="$1"

    if [ ! -f "$FILE" ]; then
        LOGE "File not found: ${FILE//$SRC_DIR\//}"
        return 1
    fi

    if IS_SPARSE_IMAGE "$FILE"; then
        local BLOCK_SIZE
        local BLOCKS
        BLOCK_SIZE="$(printf "%d" "0x$(READ_BYTES_AT "$FILE" "12" "4")")"
        BLOCKS="$(printf "%d" "0x$(READ_BYTES_AT "$FILE" "16" "4")")"

        bc -l <<< "$BLOCKS * $BLOCK_SIZE"
    else
        GET_DISK_USAGE "$FILE"
    fi
}

# [
DEPENDENCIES=(
    "7z" "awk" "basename" "bc" "brotli" "cat" "clang" "cmake"
    "cp" "cpio" "curl" "cut" "cwebp" "dd" "dirname" "du" "ffmpeg"
    "file" "fmt" "getfattr" "git" "grep" "head" "java" "ln"
    "lz4" "make" "md5sum" "mkdir" "mount" "mv" "perl" "protoc"
    "python3" "rm" "rsync" "sed" "sha1sum" "sort" "split" "stat"
    "sudo" "tail" "tar" "touch" "tr" "truncate" "umount" "unzip"
    "wc" "whoami" "xargs" "xxd" "zip" "zstd"
)
MISSING=()
for d in "${DEPENDENCIES[@]}"; do
    if ! type "$d" &> /dev/null; then
        MISSING+=("$d")
    fi
done
if [ "${#MISSING[@]}" -ne 0 ]; then
    echo -e '\033[1;31m'"The following dependencies are missing from your system:"'\033[0;31m' >&2
    printf '%s ' "${MISSING[@]}" >&2
    echo -e '\033[0m' >&2
    return 1
fi
unset DEPENDENCIES MISSING

if ! "$SRC_DIR/external/make.sh" --check-tools; then
    LOG_STEP_IN true "Building required tools..."
    "$SRC_DIR/external/make.sh" || return 1
    LOG_STEP_OUT
fi
# ]
