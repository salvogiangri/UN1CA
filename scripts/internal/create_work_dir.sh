#!/usr/bin/env bash
#
# Copyright (C) 2023 Salvo Giangreco
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
COPY_SOURCE_FIRMWARE()
{
    local MODEL
    local REGION
    MODEL=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 1)
    REGION=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 2)
    COMMON_FOLDERS="product system"
    for folder in $COMMON_FOLDERS; do
        [[ ! -d "$FW_DIR/${MODEL}_${REGION}/$folder" ]] && continue
        rsync -a --mkpath \
            "$FW_DIR/${MODEL}_${REGION}/$folder/" \
            "$WORK_DIR/$folder/"

        mkdir -p "$WORK_DIR/configs"
        rsync -a \
            "$FW_DIR/${MODEL}_${REGION}/file_context-$folder" \
            "$FW_DIR/${MODEL}_${REGION}/fs_config-$folder" \
            "$WORK_DIR/configs/"
    done

    if $SOURCE_HAS_SYSTEM_EXT; then
        if ! $TARGET_HAS_SYSTEM_EXT; then
            if [ ! -d "$WORK_DIR/system/system/system_ext" ]; then
                rm -rf "$WORK_DIR/system/system_ext"
                rm -f "$WORK_DIR/system/system/system_ext"
                sed -i "/system_ext/d" "$WORK_DIR/configs/file_context-system" \
                    && sed -i "/system_ext/d" "$WORK_DIR/configs/fs_config-system"
                cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system_ext" "$WORK_DIR/system/system"
                ln -sf "/system/system_ext" "$WORK_DIR/system/system_ext"
                echo "/system_ext u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
                echo "system_ext 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
                {
                    sed "s/^\/system_ext/\/system\/system_ext/g" "$FW_DIR/${MODEL}_${REGION}/file_context-system_ext"
                } >> "$WORK_DIR/configs/file_context-system"
                echo "system/system_ext 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
                {
                    sed "1d" "$FW_DIR/${MODEL}_${REGION}/fs_config-system_ext" | sed "s/^system_ext/system\/system_ext/g"
                } >> "$WORK_DIR/configs/fs_config-system"
                rm -f "$WORK_DIR/system/system/system_ext/etc/NOTICE.xml.gz"
                sed -i '/system\/system_ext\/etc\/NOTICE\\.xml\\.gz/d' "$WORK_DIR/configs/file_context-system"
                sed -i "/system\/system_ext\/etc\/NOTICE.xml.gz/d" "$WORK_DIR/configs/fs_config-system"
                rm -f "$WORK_DIR/system/system/system_ext/etc/fs_config_dirs"
                sed -i "/system\/system_ext\/etc\/fs_config_dirs/d" "$WORK_DIR/configs/file_context-system"
                sed -i "/system\/system_ext\/etc\/fs_config_dirs/d" "$WORK_DIR/configs/fs_config-system"
                rm -f "$WORK_DIR/system/system/system_ext/etc/fs_config_files"
                sed -i "/system\/system_ext\/etc\/fs_config_files/d" "$WORK_DIR/configs/file_context-system"
                sed -i "/system\/system_ext\/etc\/fs_config_files/d" "$WORK_DIR/configs/fs_config-system"
            fi
        elif [ ! -d "$WORK_DIR/system_ext" ]; then
            mkdir -p "$WORK_DIR/system_ext"
            cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system_ext" "$WORK_DIR"
            cp --preserve=all "$FW_DIR/${MODEL}_${REGION}/file_context-system_ext" "$WORK_DIR/configs"
            cp --preserve=all "$FW_DIR/${MODEL}_${REGION}/fs_config-system_ext" "$WORK_DIR/configs"
        fi
    else
        if $TARGET_HAS_SYSTEM_EXT; then
            # Create file structure: separate system_ext and create new symlinks in rootdir and systemdir
            cp -a -r --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/system_ext" "$WORK_DIR"
            rm -rf "$WORK_DIR/system/system/system_ext"
            rm "$WORK_DIR/system/system_ext"
            mkdir "$WORK_DIR/system/system_ext"
            ln -s "/system_ext" "$WORK_DIR/system/system/system_ext"
            # Create system_ext filesystem configs file by extracting them from system config
            grep 'system_ext' "$FW_DIR/${MODEL}_${REGION}/fs_config-system" | sed 's/^system\///' | sed '/system_ext 0 0 644 capabilities/d' | sed '/system_ext 0 0 755 capabilities/d' >> "$WORK_DIR/configs/fs_config-system_ext"
            grep 'system_ext' "$FW_DIR/${MODEL}_${REGION}/file_context-system" | sed '/system_ext u:object_r:system_file:s0/d' | sed 's/^\/system//' >> "$WORK_DIR/configs/file_context-system_ext"
            # Remove all old system_ext references in system
            sed -i '/system_ext/d' "$WORK_DIR/configs/fs_config-system"
            sed -i '/system_ext/d' "$WORK_DIR/configs/file_context-system"
            # Add new symlink and folder config in system fs config
            echo "/system/system_ext u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
            echo "/system_ext u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
            echo "system/system_ext 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
            echo "system_ext 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
            # Finish by setting the root configuration of system_ext
            echo " 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system_ext"
            echo "/system_ext u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system_ext"
        fi
    fi
}

COPY_TARGET_FIRMWARE()
{
    local MODEL
    local REGION
    MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
    REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)
    COMMON_FOLDERS="odm vendor vendor_dlkm odm_dlkm"
    for folder in $COMMON_FOLDERS; do
        [[ ! -d "$FW_DIR/${MODEL}_${REGION}/$folder" ]] && continue
        rsync -a --mkpath \
            "$FW_DIR/${MODEL}_${REGION}/$folder/" \
            "$WORK_DIR/$folder/"

        mkdir -p "$WORK_DIR/configs"
        rsync -a \
            "$FW_DIR/${MODEL}_${REGION}/file_context-$folder" \
            "$FW_DIR/${MODEL}_${REGION}/fs_config-$folder" \
            "$WORK_DIR/configs/"
    done
}

COPY_TARGET_KERNEL()
{
    local MODEL
    local REGION
    MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
    REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

    mkdir -p "$WORK_DIR/kernel"

    local COMMON_KERNEL_BINS="boot.img dtbo.img init_boot.img vendor_boot.img"
    for i in $COMMON_KERNEL_BINS; do
        [ ! -f "$FW_DIR/${MODEL}_${REGION}/$i" ] && continue
        cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$i" "$WORK_DIR/kernel/$i"
        $TARGET_KEEP_ORIGINAL_SIGN || bash "$SRC_DIR/scripts/unsign_bin.sh" "$WORK_DIR/kernel/$i" &> /dev/null
    done
    if $TARGET_INCLUDE_PATCHED_VBMETA; then
        cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/vbmeta_patched.img" "$WORK_DIR/kernel/vbmeta.img"
    fi
}
# ]

mkdir -p "$WORK_DIR"
mkdir -p "$WORK_DIR/configs"
COPY_SOURCE_FIRMWARE
COPY_TARGET_FIRMWARE
COPY_TARGET_KERNEL

exit 0
