#!/usr/bin/env bash
#
# Copyright (C) 2023 BlackMesa123
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

set -eu

# [
JOBS="$(nproc)"

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

BUILD_ANDROID_TOOLS()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building android-tools...\n"

    cd "$SRC_DIR/external/android-tools"
    mkdir -p "build" && cd "build"
    cmake ..
    make -j"$JOBS" --quiet
    find "vendor" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} "$TOOLS_DIR" \;
    cd ..
    cp --preserve=all "vendor/avb/avbtool.py" "$TOOLS_DIR/avbtool"
    cp --preserve=all "vendor/mkbootimg/mkbootimg.py" "$TOOLS_DIR/mkbootimg"
    cp --preserve=all "vendor/mkbootimg/repack_bootimg.py" "$TOOLS_DIR/repack_bootimg"
    cp --preserve=all "vendor/mkbootimg/unpack_bootimg.py" "$TOOLS_DIR/unpack_bootimg"
    mkdir -p "$TOOLS_DIR/gki" \
        && cp --preserve=all "vendor/mkbootimg/gki/generate_gki_certificate.py" "$TOOLS_DIR/gki/generate_gki_certificate.py"
    ln -sf "$TOOLS_DIR/mke2fs.android" "$TOOLS_DIR/mke2fs"
    cp --preserve=all "../ext4_utils/mkuserimg_mke2fs.py" "$TOOLS_DIR/mkuserimg_mke2fs.py" \
        && ln -sf "$TOOLS_DIR/mkuserimg_mke2fs.py" "$TOOLS_DIR/mkuserimg_mke2fs"
    cp --preserve=all "../ext4_utils/mke2fs.conf" "$TOOLS_DIR/mke2fs.conf"
    cp --preserve=all "../f2fs_utils/mkf2fsuserimg.sh" "$TOOLS_DIR/mkf2fsuserimg"

    echo ""
    cd "$PDR"
}

BUILD_APKTOOL()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building apktool...\n"

    cd "$SRC_DIR/external/apktool"
    ./gradlew build shadowJar -q
    cp --preserve=all "scripts/linux/apktool" "$TOOLS_DIR"
    cp --preserve=all "brut.apktool/apktool-cli/build/libs/apktool-cli.jar" "$TOOLS_DIR/apktool.jar"

    echo ""
    cd "$PDR"
}

BUILD_EROFS_UTILS()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building erofs-utils...\n"

    cd "$SRC_DIR/external/erofs-utils"
    cmake -S "./build/cmake" -B "./out" \
        -DCMAKE_SYSTEM_NAME="Linux" \
        -DCMAKE_SYSTEM_PROCESSOR="x86_64" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DRUN_ON_WSL="OFF" \
        -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
        -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
        -DCMAKE_C_COMPILER="clang" \
        -DCMAKE_CXX_COMPILER="clang++" \
        -DCMAKE_C_FLAGS="" \
        -DCMAKE_CXX_FLAGS="" \
        -DENABLE_FULL_LTO="ON" \
        -DMAX_BLOCK_SIZE="4096"
    make -C "./out" -j"$JOBS" --quiet
    find "out/erofs-tools" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} "$TOOLS_DIR" \;

    echo ""
    cd "$PDR"
}

BUILD_IMG2SDAT()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building img2sdat...\n"

    cd "$SRC_DIR/external/img2sdat"
    find "." -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} "$TOOLS_DIR" \;

    echo ""
    cd "$PDR"
}

BUILD_SAMFIRM()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building samfirm.js...\n"

    cd "$SRC_DIR/external/samfirm.js"
    npm install --silent
    npm run --silent build
    cp --preserve=all "dist/index.js" "$TOOLS_DIR/samfirm"

    echo ""
    cd "$PDR"
}

BUILD_SIGNAPK()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building signapk...\n"

    mkdir -p "$TOOLS_DIR/../lib64"
    cd "$SRC_DIR/external/signapk"
    cp --preserve=all "libconscrypt_openjdk_jni.so" "$TOOLS_DIR/../lib64/libconscrypt_openjdk_jni.so"
    cp --preserve=all "signapk.jar" "$TOOLS_DIR/signapk.jar"
    cp --preserve=all "signapk" "$TOOLS_DIR/signapk"

    echo ""
    cd "$PDR"
}
# ]

if [ "$#" -gt 0 ]; then
    echo "Usage: build_dependencies"
    echo "This cmd does not accepts any arguments."
    exit 1
fi

mkdir -p "$TOOLS_DIR"

ANDROID_TOOLS=true
APKTOOL=true
EROFS_UTILS=true
IMG2SDAT=true
SAMFIRM=true
SIGNAPK=true

ANDROID_TOOLS_EXEC=(
    "adb" "append2simg" "avbtool" "e2fsdroid"
    "ext2simg" "fastboot" "gki/generate_gki_certificate.py" "img2simg"
    "lpadd" "lpdump" "lpflash" "lpmake"
    "lpunpack" "make_f2fs" "mkbootimg" "mke2fs"
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

$ANDROID_TOOLS && BUILD_ANDROID_TOOLS
$APKTOOL && BUILD_APKTOOL
$EROFS_UTILS && BUILD_EROFS_UTILS
$IMG2SDAT && BUILD_IMG2SDAT
$SAMFIRM && BUILD_SAMFIRM
$SIGNAPK && BUILD_SIGNAPK

exit 0
