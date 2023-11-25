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

# shellcheck disable=SC1091,SC2069

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools/bin"
TMP_DIR="$OUT_DIR/tmp"
WORK_DIR="$OUT_DIR/work_dir"

PATH="$TOOLS_DIR:$PATH"

GET_SPARSE_IMG_SIZE()
{
    local FILE_INFO
    local BLOCKS
    local BLOCK_SIZE

    FILE_INFO=$(file -b "$1")
    if [ -z "$FILE_INFO" ] || [[ "$FILE_INFO" != "Android"* ]]; then
        exit 1
    fi

    BLOCKS=$(echo "$FILE_INFO" | grep -o "[[:digit:]]*" | sed "3p;d")
    BLOCK_SIZE=$(echo "$FILE_INFO" | grep -o "[[:digit:]]*" | sed "4p;d")

    echo "$BLOCKS * $BLOCK_SIZE" | bc -l
}

GENERATE_OP_LIST()
{
    local OP_LIST_FILE="$TMP_DIR/dynamic_partitions_op_list"
    local GROUP_NAME="group_basic"
    local HAS_SYSTEM=false
    local HAS_VENDOR=false
    local HAS_PRODUCT=false
    local HAS_SYSTEM_EXT=false
    local HAS_ODM=false
    local HAS_VENDOR_DLKM=false
    local HAS_ODM_DLKM=false
    local HAS_SYSTEM_DLKM=false

    [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && GROUP_NAME="qti_dynamic_partitions"

    [ -f "$TMP_DIR/system.img" ] && HAS_SYSTEM=true
    [ -f "$TMP_DIR/vendor.img" ] && HAS_VENDOR=true
    [ -f "$TMP_DIR/product.img" ] && HAS_PRODUCT=true
    [ -f "$TMP_DIR/system_ext.img" ] && HAS_SYSTEM_EXT=true
    [ -f "$TMP_DIR/odm.img" ] && HAS_ODM=true
    [ -f "$TMP_DIR/vendor_dlkm.img" ] && HAS_VENDOR_DLKM=true
    [ -f "$TMP_DIR/odm_dlkm.img" ] && HAS_ODM_DLKM=true
    [ -f "$TMP_DIR/system_dlkm.img" ] && HAS_SYSTEM_DLKM=true

    [ -f "$OP_LIST_FILE" ] && rm -f "$OP_LIST_FILE"
    touch "$OP_LIST_FILE"
    {
        echo "# Remove all existing dynamic partitions and groups before applying full OTA"
        echo "remove_all_groups"
        echo "# Add group $GROUP_NAME with maximum size $TARGET_SUPER_GROUP_SIZE"
        echo "add_group $GROUP_NAME $TARGET_SUPER_GROUP_SIZE"
        $HAS_SYSTEM && echo "# Add partition system to group $GROUP_NAME"
        $HAS_SYSTEM && echo "add system $GROUP_NAME"
        $HAS_VENDOR && echo "# Add partition vendor to group $GROUP_NAME"
        $HAS_VENDOR && echo "add vendor $GROUP_NAME"
        $HAS_PRODUCT && echo "# Add partition product to group $GROUP_NAME"
        $HAS_PRODUCT && echo "add product $GROUP_NAME"
        $HAS_SYSTEM_EXT && echo "# Add partition system_ext to group $GROUP_NAME"
        $HAS_SYSTEM_EXT && echo "add system_ext $GROUP_NAME"
        $HAS_ODM && echo "# Add partition odm to group $GROUP_NAME"
        $HAS_ODM && echo "add odm $GROUP_NAME"
        $HAS_VENDOR_DLKM && echo "# Add partition vendor_dlkm to group $GROUP_NAME"
        $HAS_VENDOR_DLKM && echo "add vendor_dlkm $GROUP_NAME"
        $HAS_ODM_DLKM && echo "# Add partition odm_dlkm to group $GROUP_NAME"
        $HAS_ODM_DLKM && echo "add odm_dlkm $GROUP_NAME"
        $HAS_SYSTEM_DLKM && echo "# Add partition system_dlkm to group $GROUP_NAME"
        $HAS_SYSTEM_DLKM && echo "add system_dlkm $GROUP_NAME"
        $HAS_SYSTEM && echo "# Grow partition system from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/system.img")"
        $HAS_SYSTEM && echo "resize system $(GET_SPARSE_IMG_SIZE "$TMP_DIR/system.img")"
        $HAS_VENDOR && echo "# Grow partition vendor from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/vendor.img")"
        $HAS_VENDOR && echo "resize vendor $(GET_SPARSE_IMG_SIZE "$TMP_DIR/vendor.img")"
        $HAS_PRODUCT && echo "# Grow partition product from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/product.img")"
        $HAS_PRODUCT && echo "resize product $(GET_SPARSE_IMG_SIZE "$TMP_DIR/product.img")"
        $HAS_SYSTEM_EXT && echo "# Grow partition system_ext from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/system_ext.img")"
        $HAS_SYSTEM_EXT && echo "resize system_ext $(GET_SPARSE_IMG_SIZE "$TMP_DIR/system_ext.img")"
        $HAS_ODM && echo "# Grow partition odm from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/odm.img")"
        $HAS_ODM && echo "resize odm $(GET_SPARSE_IMG_SIZE "$TMP_DIR/odm.img")"
        $HAS_VENDOR_DLKM && echo "# Grow partition vendor_dlkm from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/vendor_dlkm.img")"
        $HAS_VENDOR_DLKM && echo "resize vendor_dlkm $(GET_SPARSE_IMG_SIZE "$TMP_DIR/vendor_dlkm.img")"
        $HAS_ODM_DLKM && echo "# Grow partition odm_dlkm from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/odm_dlkm.img")"
        $HAS_ODM_DLKM && echo "resize odm_dlkm $(GET_SPARSE_IMG_SIZE "$TMP_DIR/odm_dlkm.img")"
        $HAS_SYSTEM_DLKM && echo "# Grow partition system_dlkm from 0 to $(GET_SPARSE_IMG_SIZE "$TMP_DIR/system_dlkm.img")"
        $HAS_SYSTEM_DLKM && echo "resize system_dlkm $(GET_SPARSE_IMG_SIZE "$TMP_DIR/system_dlkm.img")"
    } >> "$OP_LIST_FILE"

    true
}

GENERATE_UPDATER_SCRIPT()
{
    local SCRIPT_FILE="$TMP_DIR/META-INF/com/google/android/updater-script"
    local HAS_SYSTEM=false
    local HAS_VENDOR=false
    local HAS_PRODUCT=false
    local HAS_SYSTEM_EXT=false
    local HAS_ODM=false
    local HAS_VENDOR_DLKM=false
    local HAS_ODM_DLKM=false
    local HAS_SYSTEM_DLKM=false

    [ -f "$TMP_DIR/system.new.dat.br" ] && HAS_SYSTEM=true
    [ -f "$TMP_DIR/vendor.new.dat.br" ] && HAS_VENDOR=true
    [ -f "$TMP_DIR/product.new.dat.br" ] && HAS_PRODUCT=true
    [ -f "$TMP_DIR/system_ext.new.dat.br" ] && HAS_SYSTEM_EXT=true
    [ -f "$TMP_DIR/odm.new.dat.br" ] && HAS_ODM=true
    [ -f "$TMP_DIR/vendor_dlkm.new.dat.br" ] && HAS_VENDOR_DLKM=true
    [ -f "$TMP_DIR/odm_dlkm.new.dat.br" ] && HAS_ODM_DLKM=true
    [ -f "$TMP_DIR/system_dlkm.new.dat.br" ] && HAS_SYSTEM_DLKM=true

    [ -f "$SCRIPT_FILE" ] && rm -f "$SCRIPT_FILE"
    touch "$SCRIPT_FILE"
    {
        echo -e "\n# --- Start patching dynamic partitions ---\n\n"
        echo -e "# Update dynamic partition metadata\n"
        echo    'assert(update_dynamic_partitions(package_extract_file("dynamic_partitions_op_list")));'
        if $HAS_SYSTEM; then
            echo -e "\n# Patch partition system\n"
            echo    'ui_print("Patching system image unconditionally...");'
            echo    'block_image_update(map_partition("system"), package_extract_file("system.transfer.list"), "system.new.dat.br", "system.patch.dat") ||'
            echo    '  abort("E1001: Failed to update system image.");'
        fi
        if $HAS_VENDOR; then
            echo -e "\n# Patch partition vendor\n"
            echo    'ui_print("Patching vendor image unconditionally...");'
            echo    'block_image_update(map_partition("vendor"), package_extract_file("vendor.transfer.list"), "vendor.new.dat.br", "vendor.patch.dat") ||'
            echo    '  abort("E2001: Failed to update vendor image.");'
        fi
        if $HAS_PRODUCT; then
            echo -e "\n# Patch partition product\n"
            echo    'ui_print("Patching product image unconditionally...");'
            echo    'block_image_update(map_partition("product"), package_extract_file("product.transfer.list"), "product.new.dat.br", "product.patch.dat") ||'
            echo    '  abort("E2001: Failed to update product image.");'
        fi
        if $HAS_SYSTEM_EXT; then
            echo -e "\n# Patch partition system_ext\n"
            echo    'ui_print("Patching system_ext image unconditionally...");'
            echo    'block_image_update(map_partition("system_ext"), package_extract_file("system_ext.transfer.list"), "system_ext.new.dat.br", "system_ext.patch.dat") ||'
            echo    '  abort("E2001: Failed to update system_ext image.");'
        fi
        if $HAS_ODM; then
            echo -e "\n# Patch partition odm\n"
            echo    'ui_print("Patching odm image unconditionally...");'
            echo    'block_image_update(map_partition("odm"), package_extract_file("odm.transfer.list"), "odm.new.dat.br", "odm.patch.dat") ||'
            echo    '  abort("E2001: Failed to update odm image.");'
        fi
        if $HAS_VENDOR_DLKM; then
            echo -e "\n# Patch partition vendor_dlkm\n"
            echo    'ui_print("Patching vendor_dlkm image unconditionally...");'
            echo    'block_image_update(map_partition("vendor_dlkm"), package_extract_file("vendor_dlkm.transfer.list"), "vendor_dlkm.new.dat.br", "vendor_dlkm.patch.dat") ||'
            echo    '  abort("E2001: Failed to update vendor_dlkm image.");'
        fi
        if $HAS_ODM_DLKM; then
            echo -e "\n# Patch partition odm_dlkm\n"
            echo    'ui_print("Patching odm_dlkm image unconditionally...");'
            echo    'block_image_update(map_partition("odm_dlkm"), package_extract_file("odm_dlkm.transfer.list"), "odm_dlkm.new.dat.br", "odm_dlkm.patch.dat") ||'
            echo    '  abort("E2001: Failed to update odm_dlkm image.");'
        fi
        if $HAS_SYSTEM_DLKM; then
            echo -e "\n# Patch partition system_dlkm\n"
            echo    'ui_print("Patching system_dlkm image unconditionally...");'
            echo    'block_image_update(map_partition("system_dlkm"), package_extract_file("system_dlkm.transfer.list"), "system_dlkm.new.dat.br", "system_dlkm.patch.dat") ||'
            echo    '  abort("E2001: Failed to update system_dlkm image.");'
        fi
        echo -e "\n# --- End patching dynamic partitions ---\n"
    } >> "$SCRIPT_FILE"

    true
}

source "$OUT_DIR/config.sh"

FILE_NAME="UNICA"
# ]

echo "Set up tmp dir"
mkdir -p "$TMP_DIR"
[ -d "$TMP_DIR/META-INF/com/google/android" ] && rm -rf "$TMP_DIR/META-INF/com/google/android"
mkdir -p "$TMP_DIR/META-INF/com/google/android"
cp --preserve=all "$SRC_DIR/unica/flashable-zip/updater" "$TMP_DIR/META-INF/com/google/android/update-binary"

while read -r i; do
    PARTITION=$(basename "$i")
    [[ "$PARTITION" == "configs" ]] && continue
    [ -f "$TMP_DIR/$PARTITION.img" ] && rm -f "$TMP_DIR/$PARTITION.img"
    [ -f "$WORK_DIR/$PARTITION.img" ] && rm -f "$WORK_DIR/$PARTITION.img"

    echo "Building $PARTITION.img"
    bash -e "$SRC_DIR/scripts/build_fs_image.sh" "$TARGET_OS_FILE_SYSTEM+sparse" "$WORK_DIR/$PARTITION" \
        "$WORK_DIR/configs/file_context-$PARTITION" "$WORK_DIR/configs/fs_config-$PARTITION" 2>&1 > /dev/null
    mv "$WORK_DIR/$PARTITION.img" "$TMP_DIR/$PARTITION.img"
done <<< "$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)"

echo "Generating dynamic_partitions_op_list"
GENERATE_OP_LIST

while read -r i; do
    PARTITION="$(basename "$i" | sed "s/.img//g")"
    if [ -f "$TMP_DIR/$PARTITION.new.dat" ] || [ -f "$TMP_DIR/$PARTITION.new.dat.br" ]; then
        rm -f "$TMP_DIR/$PARTITION.new.dat" \
            && rm -f "$TMP_DIR/$PARTITION.new.dat.br" \
            && rm -f "$TMP_DIR/$PARTITION.patch.dat" \
            && rm -f "$TMP_DIR/$PARTITION.patch.dat"
    fi

    echo "Converting $PARTITION.img to $PARTITION.new.dat"
    img2sdat -o "$TMP_DIR" "$i" 2>&1 > /dev/null \
        && rm "$i"
    echo "Compressing $PARTITION.new.dat"
    brotli --quality=6 --output="$TMP_DIR/$PARTITION.new.dat.br" "$TMP_DIR/$PARTITION.new.dat" \
        && rm "$TMP_DIR/$PARTITION.new.dat"
done <<< "$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type f -name "*.img")"

echo "Generating updater-script"
GENERATE_UPDATER_SCRIPT

echo "Creating zip"
[ -f "$OUT_DIR/rom.zip" ] && rm -f "$OUT_DIR/rom.zip"
cd "$TMP_DIR" ; zip -rq ../rom.zip ./* ; cd - &> /dev/null

echo "Signing zip"
[ -f "$OUT_DIR/$FILE_NAME-sign.zip" ] && rm -f "$OUT_DIR/$FILE_NAME-sign.zip"
signapk -w \
    "$SRC_DIR/unica/flashable-zip/testkey.x509.pem" "$SRC_DIR/unica/flashable-zip/testkey.pk8" \
    "$OUT_DIR/rom.zip" "$OUT_DIR/$FILE_NAME-sign.zip" \
    && rm -f "$OUT_DIR/rom.zip"

echo "Deleting tmp dir"
rm -rf "$TMP_DIR"

exit 0
