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
# https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/envsetup.sh#18
GET_SRC_DIR()
{
    local TOPFILE="unica/config.sh"
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

CHECK_TOOLS()
{
    local EXECUTABLES=("$@")

    local EXISTS=true
    for i in "${EXECUTABLES[@]}"
    do
        [ ! -f "$TOOLS_DIR/$i" ] && EXISTS=false
    done

    $EXISTS
}

BUILD_CMAKE_FLAGS()
{
    local FLAGS=""

    FLAGS+="-DCMAKE_SYSTEM_NAME=\"$(uname -s)\" "
    FLAGS+="-DCMAKE_SYSTEM_PROCESSOR=\"$(uname -m)\" "
    FLAGS+="-DCMAKE_BUILD_TYPE=\"Release\" "
    if type ccache &> /dev/null; then
        FLAGS+="-DCMAKE_C_COMPILER_LAUNCHER=\"ccache\" "
        FLAGS+="-DCMAKE_CXX_COMPILER_LAUNCHER=\"ccache\" "
    fi
    if type clang &> /dev/null; then
        FLAGS+="-DCMAKE_C_COMPILER=\"clang\" "
        FLAGS+="-DCMAKE_CXX_COMPILER=\"clang++\""
    else
        FLAGS+="-DCMAKE_C_COMPILER=\"gcc\" "
        FLAGS+="-DCMAKE_CXX_COMPILER=\"g++\""
    fi

    echo "$FLAGS"
}

BUILD()
{
    local PDR
    PDR="$(pwd)"

    local NAME="$1"; shift
    local DIR="$1"; shift
    local CMDS=("$@")

    echo "- Building $NAME..."

    cd "$DIR"
    for CMD in "${CMDS[@]}"
    do
        local OUT
        OUT="$(eval "$CMD" 2>&1)"
        if [ $? -ne 0 ]; then
            echo -e    '\033[1;31m'"BUILD FAILED!"'\033[0m\n' >&2
            echo -e    '\033[0;31m'"$CMD"'\033[0m\n' >&2
            echo -e -n '\033[0;33m' >&2
            echo -n    "$OUT" >&2
            echo -e    '\033[0m' >&2
            exit 1
        fi
    done
    cd "$PDR"

    return 0
}
# ]

if [ "$#" -gt 0 ]; then
    echo "Usage: $(basename "$0" | sed 's/build_dependencies.sh/build_dependencies/')" >&2
    echo "This cmd does not accepts any arguments." >&2
    exit 1
fi

SRC_DIR="$(GET_SRC_DIR)"
if [ ! "$SRC_DIR" ]; then
    echo "Couldn't locate the top of the tree. Try setting SRC_DIR." >&2
    exit 1
fi
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools/bin"

mkdir -p "$TOOLS_DIR"

ANDROID_TOOLS=true
APKTOOL=true
EROFS_UTILS=true
IMG2SDAT=true
SAMFIRM=true
SIGNAPK=true
SMALI=true
ZIPALIGN=true

ANDROID_TOOLS_EXEC=(
    "adb" "append2simg" "avbtool" "e2fsdroid"
    "ext2simg" "fastboot" "gki/generate_gki_certificate.py" "img2simg"
    "lpadd" "lpdump" "lpflash" "lpmake"
    "lpunpack" "make_f2fs" "mkbootimg" "mkdtboimg" "mke2fs"
    "mke2fs.android" "mke2fs.conf" "mkf2fsuserimg" "mkuserimg_mke2fs"
    "repack_bootimg" "simg2img" "sload_f2fs" "unpack_bootimg"
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
SAMFIRM_EXEC=(
    "samfirm"
)
CHECK_TOOLS "${SAMFIRM_EXEC[@]}" && SAMFIRM=false
SIGNAPK_EXEC=(
    "signapk" "signapk.jar"
)
CHECK_TOOLS "${SIGNAPK_EXEC[@]}" && SIGNAPK=false
SMALI_EXEC=(
    "android-smali.jar" "baksmali" "smali" "smali-baksmali.jar"
)
CHECK_TOOLS "${SMALI_EXEC[@]}" && SMALI=false
ZIPALIGN_EXEC=(
    "zipalign"
)
CHECK_TOOLS "${ZIPALIGN_EXEC[@]}" && ZIPALIGN=false

if $ANDROID_TOOLS; then
    ANDROID_TOOLS_CMDS=(
        "git submodule foreach --recursive git am --abort || true"
        "git submodule foreach --recursive git reset --hard"
        "cmake -B \"build\" $(BUILD_CMAKE_FLAGS) -DANDROID_TOOLS_USE_BUNDLED_FMT=ON -DANDROID_TOOLS_USE_BUNDLED_LIBUSB=ON"
        "git -C \"vendor/f2fs-tools\" apply \"$SRC_DIR/external/patches/android-tools/0001-Revert-f2fs-tools-give-6-sections-for-overprovision-.patch\""
        "make -C \"build\" -j\"$(nproc)\""
        "find \"build/vendor\" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} \"$TOOLS_DIR\" \;"
        "cp --preserve=all \"vendor/avb/avbtool.py\" \"$TOOLS_DIR/avbtool\""
        "cp --preserve=all \"vendor/mkbootimg/mkbootimg.py\" \"$TOOLS_DIR/mkbootimg\""
        "cp --preserve=all \"vendor/mkbootimg/repack_bootimg.py\" \"$TOOLS_DIR/repack_bootimg\""
        "cp --preserve=all \"vendor/mkbootimg/unpack_bootimg.py\" \"$TOOLS_DIR/unpack_bootimg\""
        "cp --preserve=all \"vendor/libufdt/utils/src/mkdtboimg.py\" \"$TOOLS_DIR/mkdtboimg\""
        "mkdir -p \"$TOOLS_DIR/gki\""
        "cp --preserve=all \"vendor/mkbootimg/gki/generate_gki_certificate.py\" \"$TOOLS_DIR/gki/generate_gki_certificate.py\""
        "ln -sf \"$TOOLS_DIR/mke2fs.android\" \"$TOOLS_DIR/mke2fs\""
        "cp --preserve=all \"../ext4_utils/mkuserimg_mke2fs.py\" \"$TOOLS_DIR/mkuserimg_mke2fs.py\""
        "ln -sf \"$TOOLS_DIR/mkuserimg_mke2fs.py\" \"$TOOLS_DIR/mkuserimg_mke2fs\""
        "cp --preserve=all \"../ext4_utils/mke2fs.conf\" \"$TOOLS_DIR/mke2fs.conf\""
        "cp --preserve=all \"../f2fs_utils/mkf2fsuserimg.sh\" \"$TOOLS_DIR/mkf2fsuserimg\""
    )

    BUILD "android-tools" "$SRC_DIR/external/android-tools" "${ANDROID_TOOLS_CMDS[@]}"
fi
if $APKTOOL; then
    APKTOOL_CMDS=(
        "git reset --hard"
        "git apply \"$SRC_DIR/external/patches/apktool/0001-feat-support-aapt-optimization.patch\""
        "./gradlew build shadowJar"
        "cp --preserve=all \"scripts/linux/apktool\" \"$TOOLS_DIR\""
        "cp --preserve=all \"brut.apktool/apktool-cli/build/libs/apktool-cli.jar\" \"$TOOLS_DIR/apktool.jar\""
    )

    BUILD "apktool" "$SRC_DIR/external/apktool" "${APKTOOL_CMDS[@]}"
fi
if $EROFS_UTILS; then
    EROFS_UTILS_CMDS=(
        "cmake -S \"build/cmake\" -B \"out\" $(BUILD_CMAKE_FLAGS) -DRUN_ON_WSL=\"OFF\" -DENABLE_FULL_LTO=\"ON\" -DMAX_BLOCK_SIZE=\"4096\""
        "make -C \"out\" -j\"$(nproc)\""
        "find \"out/erofs-tools\" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} \"$TOOLS_DIR\" \;"
    )

    BUILD "erofs-utils" "$SRC_DIR/external/erofs-utils" "${EROFS_UTILS_CMDS[@]}"
fi
if $IMG2SDAT; then
    IMG2SDAT_CMDS=(
        "find \".\" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} \"$TOOLS_DIR\" \;"
    )

    BUILD "img2sdat" "$SRC_DIR/external/img2sdat" "${IMG2SDAT_CMDS[@]}"
fi
if $SAMFIRM; then
    SAMFIRM_CMDS=(
        "npm install"
        "npm run build"
        "cp --preserve=all \"dist/index.js\" \"$TOOLS_DIR/samfirm\""
    )

    BUILD "samfirm.js" "$SRC_DIR/external/samfirm.js" "${SAMFIRM_CMDS[@]}"
fi
if $SIGNAPK; then
    SIGNAPK_CMDS=(
        "mkdir -p \"$TOOLS_DIR/../lib64\""
        "cp --preserve=all \"libconscrypt_openjdk_jni.so\" \"$TOOLS_DIR/../lib64/libconscrypt_openjdk_jni.so\""
        "cp --preserve=all \"signapk.jar\" \"$TOOLS_DIR/signapk.jar\""
        "cp --preserve=all \"signapk\" \"$TOOLS_DIR/signapk\""
    )

    BUILD "signapk" "$SRC_DIR/external/signapk" "${SIGNAPK_CMDS[@]}"
fi
if $SMALI; then
    SMALI_CMDS=(
        "./gradlew assemble baksmali:fatJar smali:fatJar"
        "cp --preserve=all \"scripts/baksmali\" \"$TOOLS_DIR\""
        "cp --preserve=all \"scripts/smali\" \"$TOOLS_DIR\""
        "cp --preserve=all \"baksmali/build/libs/\"*-dev-fat.jar \"$TOOLS_DIR/smali-baksmali.jar\""
        "cp --preserve=all \"smali/build/libs/\"*-dev-fat.jar \"$TOOLS_DIR/android-smali.jar\""
    )

    BUILD "baksmali/smali" "$SRC_DIR/external/smali" "${SMALI_CMDS[@]}"
fi
if $ZIPALIGN; then
    ZIPALIGN_CMDS=(
        "mkdir -p \"$TOOLS_DIR/../lib64\""
        "cp --preserve=all \"libc++.so\" \"$TOOLS_DIR/../lib64/libc++.so\""
        "cp --preserve=all \"zipalign\" \"$TOOLS_DIR/zipalign\""
    )

    BUILD "zipalign" "$SRC_DIR/external/zipalign" "${ZIPALIGN_CMDS[@]}"
fi

exit 0
