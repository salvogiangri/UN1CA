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

set -Eeuo pipefail

# [
GENERATE_LPMAKE_OPT()
{
    local OPT
    local GROUP_NAME="qti_dynamic_partitions"
    local HAS_SYSTEM=false
    local HAS_VENDOR=false
    local HAS_PRODUCT=false
    local HAS_SYSTEM_EXT=false
    local HAS_ODM=false
    local HAS_VENDOR_DLKM=false
    local HAS_ODM_DLKM=false
    local HAS_SYSTEM_DLKM=false

    [ -f "$TMP_DIR/system.img" ] && HAS_SYSTEM=true
    [ -f "$TMP_DIR/vendor.img" ] && HAS_VENDOR=true
    [ -f "$TMP_DIR/product.img" ] && HAS_PRODUCT=true
    [ -f "$TMP_DIR/system_ext.img" ] && HAS_SYSTEM_EXT=true
    [ -f "$TMP_DIR/odm.img" ] && HAS_ODM=true
    [ -f "$TMP_DIR/vendor_dlkm.img" ] && HAS_VENDOR_DLKM=true
    [ -f "$TMP_DIR/odm_dlkm.img" ] && HAS_ODM_DLKM=true
    [ -f "$TMP_DIR/system_dlkm.img" ] && HAS_SYSTEM_DLKM=true

    OPT+="--sparse"
    OPT+=" -o $TMP_DIR/super.img"
    OPT+=" --device-size $TARGET_SUPER_PARTITION_SIZE"
    OPT+=" --metadata-size 65536 --metadata-slots 2"
    OPT+=" -g $GROUP_NAME:$TARGET_SUPER_GROUP_SIZE"

    if $HAS_SYSTEM; then
        OPT+=" -p system:readonly:$(wc -c "$TMP_DIR/system.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_VENDOR; then
        OPT+=" -p vendor:readonly:$(wc -c "$TMP_DIR/vendor.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_PRODUCT; then
        OPT+=" -p product:readonly:$(wc -c "$TMP_DIR/product.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_SYSTEM_EXT; then
        OPT+=" -p system_ext:readonly:$(wc -c "$TMP_DIR/system_ext.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_ODM; then
        OPT+=" -p odm:readonly:$(wc -c "$TMP_DIR/odm.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_VENDOR_DLKM; then
        OPT+=" -p vendor_dlkm:readonly:$(wc -c "$TMP_DIR/vendor_dlkm.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_ODM_DLKM; then
        OPT+=" -p odm_dlkm:readonly:$(wc -c "$TMP_DIR/odm_dlkm.img" | cut -d " " -f 1):$GROUP_NAME"
    fi
    if $HAS_SYSTEM_DLKM; then
        OPT+=" -p system_dlkm:readonly:$(wc -c "$TMP_DIR/system_dlkm.img" | cut -d " " -f 1):$GROUP_NAME"
    fi

    if $HAS_SYSTEM; then
        OPT+=" -i system=$TMP_DIR/system.img"
    fi
    if $HAS_VENDOR; then
        OPT+=" -i vendor=$TMP_DIR/vendor.img"
    fi
    if $HAS_PRODUCT; then
        OPT+=" -i product=$TMP_DIR/product.img"
    fi
    if $HAS_SYSTEM_EXT; then
        OPT+=" -i system_ext=$TMP_DIR/system_ext.img"
    fi
    if $HAS_ODM; then
        OPT+=" -i odm=$TMP_DIR/odm.img"
    fi
    if $HAS_VENDOR_DLKM; then
        OPT+=" -i vendor_dlkm=$TMP_DIR/vendor_dlkm.img"
    fi
    if $HAS_ODM_DLKM; then
        OPT+=" -i odm_dlkm=$TMP_DIR/odm_dlkm.img"
    fi
    if $HAS_SYSTEM_DLKM; then
        OPT+=" -i system_dlkm=$TMP_DIR/system_dlkm.img"
    fi

    echo "$OPT"
}

FILE_NAME="UN1CA_${ROM_VERSION}_$(date +%Y%m%d)_${TARGET_CODENAME}"
# ]

echo "Set up tmp dir"
mkdir -p "$TMP_DIR"

while read -r i; do
    PARTITION=$(basename "$i")
    [[ "$PARTITION" == "configs" ]] && continue
    [[ "$PARTITION" == "kernel" ]] && continue
    [ -f "$TMP_DIR/$PARTITION.img" ] && rm -f "$TMP_DIR/$PARTITION.img"
    [ -f "$WORK_DIR/$PARTITION.img" ] && rm -f "$WORK_DIR/$PARTITION.img"

    echo "Building $PARTITION.img"
    bash "$SRC_DIR/scripts/build_fs_image.sh" "$TARGET_OS_FILE_SYSTEM" "$WORK_DIR/$PARTITION" \
        "$WORK_DIR/configs/file_context-$PARTITION" "$WORK_DIR/configs/fs_config-$PARTITION" > /dev/null 2>&1
    mv "$WORK_DIR/$PARTITION.img" "$TMP_DIR/$PARTITION.img"
done <<< "$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)"

echo "Building super.img"
[ -f "$TMP_DIR/super.img" ] && rm -f "$TMP_DIR/super.img"
CMD="lpmake $(GENERATE_LPMAKE_OPT)"
$CMD &> /dev/null
for i in "$TMP_DIR"/*; do
    [[ "$i" == *"super.img" ]] && continue
    rm -f "$i"
done

while read -r i; do
    IMG="$(basename "$i")"
    echo "Copying $IMG"
    [ -f "$TMP_DIR/$IMG" ] && rm -f "$TMP_DIR/$IMG"
    cp -a --preserve=all "$i" "$TMP_DIR/$IMG"
done <<< "$(find "$WORK_DIR/kernel" -mindepth 1 -maxdepth 1 -type f -name "*.img")"

for i in "$TMP_DIR"/*.img; do
    echo "Compressing $(basename "$i")"
    [ -f "$i.lz4" ] && rm -f "$i.lz4"
    lz4 -B6 --content-size -q --rm "$i" "$i.lz4" &> /dev/null
done

echo "Creating tar"
[ -f "$OUT_DIR/$FILE_NAME.tar" ] && rm -f "$OUT_DIR/$FILE_NAME.tar"
cd "$TMP_DIR" ; tar -c --format=gnu -f "$OUT_DIR/$FILE_NAME.tar" -- *.lz4 ; cd - &> /dev/null

echo "Generating checksum"
[ -f "$OUT_DIR/$FILE_NAME.tar.md5" ] && rm -f "$OUT_DIR/$FILE_NAME.tar.md5"
CHECKSUM="$(md5sum "$OUT_DIR/$FILE_NAME.tar" | cut -d " " -f 1 | sed 's/ //')"
echo -n "$CHECKSUM" >> "$OUT_DIR/$FILE_NAME.tar" \
    && echo "  $FILE_NAME.tar" >> "$OUT_DIR/$FILE_NAME.tar" \
    && mv "$OUT_DIR/$FILE_NAME.tar" "$OUT_DIR/$FILE_NAME.tar.md5"

echo "Deleting tmp dir"
rm -rf "$TMP_DIR"

exit 0
