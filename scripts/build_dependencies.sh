#!/bin/bash
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

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools/bin"

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
    make -j$(nproc) --quiet
    find "vendor" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} "$TOOLS_DIR" \;
    cd ..
    cp --preserve=all "vendor/avb/avbtool.py" "$TOOLS_DIR/avbtool"
    cp --preserve=all "vendor/mkbootimg/mkbootimg.py" "$TOOLS_DIR/mkbootimg"
    cp --preserve=all "vendor/mkbootimg/repack_bootimg.py" "$TOOLS_DIR/repack_bootimg"
    cp --preserve=all "vendor/mkbootimg/unpack_bootimg.py" "$TOOLS_DIR/unpack_bootimg"
    mkdir -p "$TOOLS_DIR/gki" && cp --preserve=all "vendor/mkbootimg/gki/generate_gki_certificate.py" "$TOOLS_DIR/gki/generate_gki_certificate.py"

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
    cp --preserve=all "brut.apktool/apktool-cli/build/libs/apktool-cli-all.jar" "$TOOLS_DIR/apktool.jar"

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
    make -C "./out" -j$(nproc) --quiet
    find "out/erofs-tools" -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} "$TOOLS_DIR" \;

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

BUILD_SMALI()
{
    local PDR
    PDR="$(pwd)"

    echo -e "- Building baksmali/smali...\n"

    cd "$SRC_DIR/external/smali"
    ./gradlew build -q
    cp --preserve=all "scripts/baksmali" "$TOOLS_DIR"
    cp --preserve=all "scripts/smali" "$TOOLS_DIR"
    cp --preserve=all "baksmali/build/libs/"*-dev-fat.jar "$TOOLS_DIR/baksmali.jar"
    cp --preserve=all "smali/build/libs/"*-dev-fat.jar "$TOOLS_DIR/smali.jar"

    echo ""
    cd "$PDR"
}
# ]

mkdir -p "$TOOLS_DIR"

ANDROID_TOOLS=true
APKTOOL=true
EROFS_UTILS=true
SAMFIRM=true
SMALI=true

ANDROID_TOOLS_EXEC=(
    "adb" "append2simg" "avbtool" "e2fsdroid"
    "ext2simg" "fastboot" "gki/generate_gki_certificate.py" "img2simg"
    "lpadd" "lpdump" "lpflash" "lpmake"
    "lpunpack" "make_f2fs" "mke2fs.android" "mkbootimg"
    "repack_bootimg" "simg2img" "unpack_bootimg"
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
SAMFIRM_EXEC=(
    "samfirm"
)
CHECK_TOOLS "${SAMFIRM_EXEC[@]}" && SAMFIRM=false
SMALI_EXEC=(
    "baksmali" "baksmali.jar" "smali" "smali.jar"
)
CHECK_TOOLS "${SMALI_EXEC[@]}" && SMALI=false

$ANDROID_TOOLS && BUILD_ANDROID_TOOLS
$APKTOOL && BUILD_APKTOOL
$EROFS_UTILS && BUILD_EROFS_UTILS
$SAMFIRM && BUILD_SAMFIRM
$SMALI && BUILD_SMALI

exit 0;
