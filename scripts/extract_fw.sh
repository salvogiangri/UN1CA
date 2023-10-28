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
ODIN_DIR="$OUT_DIR/odin"
FW_DIR="$OUT_DIR/fw"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"

EXTRACT_KERNEL_BINARIES()
{
    local PDR
    PDR="$(pwd)"

    local FILES="boot.img.lz4 dtbo.img.lz4 init_boot.img.lz4 vendor_boot.img.lz4"

    echo "- Extracting kernel binaries..."
    cd "$FW_DIR/${MODEL}_${REGION}"
    for file in $FILES
    do
        [ -f "${file%.lz4}" ] && continue
        tar tf "$AP_TAR" "$file" &>/dev/null || continue
        tar xf "$AP_TAR" "$file" && lz4 -d --rm "$file" "${file%.lz4}"
    done

    cd "$PDR"
}

EXTRACT_OS_PARTITIONS()
{
    local PDR
    PDR="$(pwd)"

    local SHOULD_EXTRACT=false
    local SHOULD_EXTRACT_SUPER=false

    echo "- Extracting OS partitions..."
    cd "$FW_DIR/${MODEL}_${REGION}"

    local COMMON_FOLDERS="odm product system vendor"
    for folder in $COMMON_FOLDERS
    do
        [ ! -d "$folder" ] && SHOULD_EXTRACT=true
        [ ! -f "$folder.img" ] && SHOULD_EXTRACT_SUPER=true
    done

    if $SHOULD_EXTRACT; then
        if [ ! -f "lpdump" ] || $SHOULD_EXTRACT_SUPER; then
            tar xf "$AP_TAR" "super.img.lz4"
            lz4 -d --rm "super.img.lz4" "super.img.sparse"
            simg2img "super.img.sparse" "super.img" && rm "super.img.sparse"
            lpunpack "super.img"
            lpdump "super.img" > "lpdump" && rm "super.img"
        fi

        [ -d "tmp_out" ] && sudo umount "tmp_out"
        mkdir -p "tmp_out"
        for img in *.img
        do
            local PARTITION="${img%.img}"
            local TYPE="$(file -b "$img")"

            case "$TYPE" in
                "EROFS"*)
                    fuse.erofs "$img" "tmp_out"
                    ;;
                "F2FS"* | *"rev 1.0 ext"*)
                    sudo mount "$img" "tmp_out"
                    ;;
                *)
                    echo "Ignoring $img"
                    continue
                    ;;
            esac

            [ -d "$PARTITION" ] && rm -rf "$PARTITION"
            mkdir -p "$PARTITION"
            sudo cp -a --preserve=all tmp_out/* "$PARTITION"
            for i in $(sudo find "$PARTITION"); do
                sudo chown -h "$(whoami)":"$(whoami)" "$i"
            done

            [ -f "file_context-$PARTITION" ] && rm "file_context-$PARTITION"
            [ -f "fs_config-$PARTITION" ] && rm "fs_config-$PARTITION"
            for i in $(sudo find "tmp_out"); do
                {
                    echo -n "$i "
                    sudo getfattr -n security.selinux --only-values -h "$i"
                    echo ""
                } >> "file_context-$PARTITION"
                echo "$(sudo stat -c "%n %u %g %a capabilities=0x0" "$i")" >> "fs_config-$PARTITION"
            done
            if [ "$PARTITION" = "system" ]; then
                sed -i "s/tmp_out /\/ /g" "file_context-$PARTITION" \
                    && sed -i "s/tmp_out\//\//g" "file_context-$PARTITION"
                sed -i "s/tmp_out / /g" "fs_config-$PARTITION" \
                    && sed -i "s/tmp_out\///g" "fs_config-$PARTITION"
            else
                sed -i "s/tmp_out/\/$PARTITION/g" "file_context-$PARTITION"
                sed -i "s/tmp_out / /g" "fs_config-$PARTITION" \
                    && sed -i "s/tmp_out/$PARTITION/g" "fs_config-$PARTITION"
            fi
            sed -i 's/\./\\./g' "file_context-$PARTITION" \
                && sed -i 's/\+/\\+/g' "file_context-$PARTITION" \
                && sed -i 's/\[/\\[/g' "file_context-$PARTITION"

            sudo umount "tmp_out"
            rm "$img"
        done

        rm -r "tmp_out"
    fi

    cd "$PDR"
}

EXTRACT_AVB_BINARIES()
{
    local PDR
    PDR="$(pwd)"

    echo "- Extracting AVB binaries..."
    cd "$FW_DIR/${MODEL}_${REGION}"
    if [ ! -f "vbmeta.img" ] && tar tf "$AP_TAR" "vbmeta.img.lz4" &>/dev/null; then
        tar xf "$AP_TAR" "vbmeta.img.lz4" && lz4 -d --rm "vbmeta.img.lz4"
    fi
    if [ ! -f "vbmeta_patched.img" ]; then
        cp --preserve=all "vbmeta.img" "vbmeta_patched.img"
        printf "$(printf '\\x%02X' 3)" | dd of="vbmeta_patched.img" bs=1 seek=123 count=1 conv=notrunc &> /dev/null
    fi

    cd "$PDR"
}
# ]

source "$OUT_DIR/config.sh"
[ "${#FIRMWARES[@]}" -ge "1" ] || exit 1

mkdir -p "$FW_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)

    if [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
        echo -e "- Extracting $MODEL firmware with $REGION CSC...\n"

        AP_TAR=$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "AP*")

        mkdir -p "$FW_DIR/${MODEL}_${REGION}"
        EXTRACT_KERNEL_BINARIES
        EXTRACT_OS_PARTITIONS
        EXTRACT_AVB_BINARIES
    else
        echo -e "- $MODEL firmware with $REGION CSC is not downloaded. Skipping...\n"
    fi
done

exit 0
