#!/bin/bash
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

# shellcheck disable=SC1007,SC2164,SC2181,SC2291

# [
BUILD()
{
    local PDR
    PDR="$(pwd)"

    local NAME="$1"; shift
    local DIR="$1"; shift
    local CMDS=("$@")

    LOG "- Building $NAME..."

    cd "$DIR"
    for CMD in "${CMDS[@]}"; do
        local OUT
        OUT="$(eval "$CMD" 2>&1)"
        if [ $? -ne 0 ]; then
            echo -e    '\033[1;31m'"BUILD FAILED!"'\033[0m\n' >&2
            echo -e    '\033[0;31m'"$CMD"'\033[0m\n' >&2
            echo -n -e '\033[0;33m' >&2
            echo -n    "$OUT" >&2
            echo -e    '\033[0m' >&2
            exit 1
        fi
    done
    cd "$PDR"

    return 0
}

CHECK_TOOLS()
{
    local EXECUTABLES=("$@")

    local EXISTS=true
    for i in "${EXECUTABLES[@]}"; do
        [ ! -f "$TOOLS_DIR/bin/$i" ] && EXISTS=false
    done

    $EXISTS
}

GET_CMAKE_FLAGS()
{
    local FLAGS

    FLAGS+="-DCMAKE_SYSTEM_NAME=\"$(uname -s)\" "
    FLAGS+="-DCMAKE_SYSTEM_PROCESSOR=\"$(uname -m)\" "
    FLAGS+="-DCMAKE_BUILD_TYPE=\"Release\" "
    if type ccache &> /dev/null; then
        FLAGS+="-DCMAKE_C_COMPILER_LAUNCHER=\"ccache\" "
        FLAGS+="-DCMAKE_CXX_COMPILER_LAUNCHER=\"ccache\" "
    fi
    FLAGS+="-DCMAKE_C_COMPILER=\"clang\" "
    FLAGS+="-DCMAKE_CXX_COMPILER=\"clang++\""

    echo "$FLAGS"
}

# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/envsetup.sh#18
GET_SRC_DIR()
{
    local TOPFILE="unica/configs/version.sh"
    if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/$TOPFILE" ]; then
        # The following circumlocution ensures we remove symlinks from SRC_DIR.
        (cd "$SRC_DIR"; PWD= /bin/pwd)
    else
        if [ -f "$TOPFILE" ]; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE="$PWD"
            local T=
            while [ \( ! \( -f "$TOPFILE" \) \) ] && [ \( "$PWD" != "/" \) ]; do
                \cd ..
                T="$(PWD= /bin/pwd -P)"
            done
            \cd "$HERE"
            if [ -f "$T/$TOPFILE" ]; then
                echo "$T"
            fi
        fi
    fi
}

# https://github.com/canonical/snapd/blob/ec7ea857712028b7e3be7a5f4448df575216dbfd/release/release.go#L169-L190
IS_WSL()
{
    if [ -e "/proc/sys/fs/binfmt_misc/WSLInterop" ] || [ -e "/run/WSL" ]; then
        echo "ON"
    else
        echo "OFF"
    fi
}
# ]

SRC_DIR="$(GET_SRC_DIR)"
if [ ! "$SRC_DIR" ]; then
    echo "Couldn't locate the top of the tree. Try setting SRC_DIR." >&2
    exit 1
else
    source "$SRC_DIR/scripts/utils/log_utils.sh" || exit 1
fi
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools"

mkdir -p "$TOOLS_DIR/bin"

ANDROID_TOOLS=true
APKTOOL=true
EROFS_UTILS=true
IMG2SDAT=true
SAMLOADER=true
SIGNAPK=true

ANDROID_TOOLS_EXEC=(
    "adb" "append2simg" "avbtool" "e2fsdroid"
    "ext2simg" "fastboot" "fec" "gki/generate_gki_certificate.py"
    "img2simg" "lpadd" "lpdump" "lpflash" "lpmake"
    "lpunpack" "make_f2fs" "mkbootfs" "mkbootimg" "mkdtboimg" "mke2fs"
    "mke2fs.android" "mke2fs.conf" "mkf2fsuserimg" "mkuserimg_mke2fs"
    "repack_bootimg" "simg2img" "sload_f2fs" "unpack_bootimg" "zipalign"
)
CHECK_TOOLS "${ANDROID_TOOLS_EXEC[@]}" && ANDROID_TOOLS=false
APKTOOL_EXEC=(
    "apktool" "apktool.jar"
)
CHECK_TOOLS "${APKTOOL_EXEC[@]}" && APKTOOL=false
EROFS_UTILS_EXEC=(
    "dump.erofs" "extract.erofs" "fsck.erofs" "fuse.erofs" "mkfs.erofs"
)
CHECK_TOOLS "${EROFS_UTILS_EXEC[@]}" && EROFS_UTILS=false
IMG2SDAT_EXEC=(
    "blockimgdiff.py" "common.py" "images.py" "img2sdat" "rangelib.py" "sparse_img.py"
)
CHECK_TOOLS "${IMG2SDAT_EXEC[@]}" && IMG2SDAT=false
SAMLOADER_EXEC=(
    "../venv/bin/samloader"
)
CHECK_TOOLS "${SAMLOADER_EXEC[@]}" && SAMLOADER=false
SIGNAPK_EXEC=(
    "signapk" "signapk.jar"
)
CHECK_TOOLS "${SIGNAPK_EXEC[@]}" && SIGNAPK=false

if [[ "$1" == "--check-tools" ]]; then
    if ! $ANDROID_TOOLS && \
            ! $APKTOOL && \
            ! $EROFS_UTILS && \
            ! $IMG2SDAT && \
            ! $SAMLOADER && \
            ! $SIGNAPK; then
        exit 0
    else
        exit 1
    fi
elif [ "$1" ]; then
    echo "Usage: $(basename "$0" | sed 's/build_dependencies.sh/build_dependencies/')" >&2
    echo "This script does not accept any arguments." >&2
    exit 1
fi

if $ANDROID_TOOLS; then
    ANDROID_TOOLS_CMDS=(
        "git submodule foreach --recursive \"git am --abort || true\""
        "cmake -B \"build\" $(GET_CMAKE_FLAGS) -DANDROID_TOOLS_USE_BUNDLED_FMT=ON -DANDROID_TOOLS_USE_BUNDLED_LIBUSB=ON"
        "make -C \"build\" -j\"$(nproc)\""
        "find \"build/vendor\" -maxdepth 1 -type f -exec test -x {} \; -exec cp -a {} \"$TOOLS_DIR/bin\" \;"
        "cp -a \"vendor/avb/avbtool.py\" \"$TOOLS_DIR/bin/avbtool\""
        "cp -a \"vendor/mkbootimg/mkbootimg.py\" \"$TOOLS_DIR/bin/mkbootimg\""
        "cp -a \"vendor/mkbootimg/repack_bootimg.py\" \"$TOOLS_DIR/bin/repack_bootimg\""
        "cp -a \"vendor/mkbootimg/unpack_bootimg.py\" \"$TOOLS_DIR/bin/unpack_bootimg\""
        "cp -a \"vendor/libufdt/utils/src/mkdtboimg.py\" \"$TOOLS_DIR/bin/mkdtboimg\""
        "mkdir -p \"$TOOLS_DIR/bin/gki\""
        "cp -a \"vendor/mkbootimg/gki/generate_gki_certificate.py\" \"$TOOLS_DIR/bin/gki/generate_gki_certificate.py\""
        "ln -sf \"$TOOLS_DIR/bin/mke2fs.android\" \"$TOOLS_DIR/bin/mke2fs\""
        "cp -a \"../ext4_utils/mkuserimg_mke2fs.py\" \"$TOOLS_DIR/bin/mkuserimg_mke2fs.py\""
        "ln -sf \"$TOOLS_DIR/bin/mkuserimg_mke2fs.py\" \"$TOOLS_DIR/bin/mkuserimg_mke2fs\""
        "cp -a \"../ext4_utils/mke2fs.conf\" \"$TOOLS_DIR/bin/mke2fs.conf\""
        "cp -a \"../f2fs_utils/mkf2fsuserimg.sh\" \"$TOOLS_DIR/bin/mkf2fsuserimg\""
    )

    BUILD "android-tools" "$SRC_DIR/external/android-tools" "${ANDROID_TOOLS_CMDS[@]}"
fi
if $APKTOOL; then
    APKTOOL_CMDS=(
        "git reset --hard"
        "git apply \"$SRC_DIR/external/patches/apktool/0001-feat-support-aapt-optimization.patch\""
        "./gradlew build shadowJar"
        "cp -a \"scripts/linux/apktool\" \"$TOOLS_DIR/bin\""
        "cp -a \"brut.apktool/apktool-cli/build/libs/apktool-cli.jar\" \"$TOOLS_DIR/bin/apktool.jar\""
    )

    BUILD "apktool" "$SRC_DIR/external/apktool" "${APKTOOL_CMDS[@]}"
fi
if $EROFS_UTILS; then
    EROFS_UTILS_CMDS=(
        "git reset --hard"
        "git apply \"$SRC_DIR/external/patches/erofs-utils/0001-Revert-AOSP-erofs-utils-mkfs-remove-block-list-imple.patch\""
        "cmake -S \"build/cmake\" -B \"out\" $(GET_CMAKE_FLAGS) -DRUN_ON_WSL=\"$(IS_WSL)\" -DENABLE_FULL_LTO=\"ON\" -DMAX_BLOCK_SIZE=\"4096\""
        "make -C \"out\" -j\"$(nproc)\""
        "find \"out/erofs-tools\" -maxdepth 1 -type f -exec test -x {} \; -exec cp -a {} \"$TOOLS_DIR/bin\" \;"
    )

    BUILD "erofs-utils" "$SRC_DIR/external/erofs-utils" "${EROFS_UTILS_CMDS[@]}"
fi
if $IMG2SDAT; then
    IMG2SDAT_CMDS=(
        "find \".\" -maxdepth 1 -type f -exec test -x {} \; -exec cp -a {} \"$TOOLS_DIR/bin\" \;"
    )

    BUILD "img2sdat" "$SRC_DIR/external/img2sdat" "${IMG2SDAT_CMDS[@]}"
fi
if $SAMLOADER; then
    SAMLOADER_CMDS=(
        "python3 -m venv \"$TOOLS_DIR/venv\""
        "source \"$TOOLS_DIR/venv/bin/activate\"; pip3 install ."
    )

    BUILD "samloader" "$SRC_DIR/external/samloader" "${SAMLOADER_CMDS[@]}"
fi
if $SIGNAPK; then
    SIGNAPK_CMDS=(
        "./gradlew build"
        "cp -a \"scripts/linux/signapk\" \"$TOOLS_DIR/bin\""
        "cp -a \"signapk/build/libs/signapk-all.jar\" \"$TOOLS_DIR/bin/signapk.jar\""
    )

    BUILD "signapk" "$SRC_DIR/external/signapk" "${SIGNAPK_CMDS[@]}"
fi

exit 0
