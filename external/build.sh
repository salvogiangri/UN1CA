#!/bin/bash

set -e

#BUILD android-tools
cd android-tools
mkdir build && cd build
cmake ..
make
find vendor -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} ../../../out/bin \;
cd ../..

#BUILD apktool
cd apktool
./gradlew build shadowJar
cp --preserve=all scripts/linux/apktool ../../out/bin
cp --preserve=all brut.apktool/apktool-cli/build/libs/apktool-cli-all.jar ../../out/bin/apktool.jar
cd ..

#BUILD erofs-utils
cd erofs-utils
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
make -C "./out" -j$(nproc)
find out/erofs-tools -maxdepth 1 -type f -exec test -x {} \; -exec cp --preserve=all {} ../../out/bin \;
cd ..

#BUILD samfirm.js
cd samfirm.js
npm install
npm run build
cp --preserve=all dist/index.js ../../out/bin/samfirm
cd ..

#BUILD smali
cd smali
./gradlew build
cp --preserve=all scripts/baksmali ../../out/bin
cp --preserve=all scripts/smali ../../out/bin
cp --preserve=all baksmali/build/libs/*-dev-fat.jar ../../out/bin/baksmali.jar
cp --preserve=all smali/build/libs/*-dev-fat.jar ../../out/bin/smali.jar
cd ..
