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

# shellcheck disable=SC1091,SC2005

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
ODIN_DIR="$OUT_DIR/odin"
FW_DIR="$OUT_DIR/fw"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"

GET_IMG_FS_TYPE()
{
    [[ "$(xxd -p -l "2" --skip "1080" "$1")" == "53ef" ]] && echo "ext4"
    [[ "$(xxd -p -l "4" --skip "1024" "$1")" == "1020f5f2" ]] && echo "f2fs"
    [[ "$(xxd -p -l "4" --skip "1024" "$1")" == "e2e1f5e0" ]] && echo "erofs" \
        || echo "unknown"
}

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
            local PREFIX=""
            local PARTITION="${img%.img}"

            case "$(GET_IMG_FS_TYPE "$img")" in
                "erofs")
                    PREFIX=""
                    [ -d "$PARTITION" ] && rm -rf "$PARTITION"
                    mkdir -p "$PARTITION"
                    fuse.erofs "$img" "tmp_out"
                    cp -a --preserve=all tmp_out/* "$PARTITION"
                    ;;
                "f2fs" | "ext4")
                    PREFIX="sudo"
                    [ -d "$PARTITION" ] && rm -rf "$PARTITION"
                    mkdir -p "$PARTITION"
                    $PREFIX mount "$img" "tmp_out"
                    $PREFIX cp -a --preserve=all tmp_out/* "$PARTITION"
                    for i in $($PREFIX find "$PARTITION"); do
                        $PREFIX chown -h "$(whoami)":"$(whoami)" "$i"
                    done
                    [[ -e "$PARTITION/lost+found" ]] && rm -rf "$PARTITION/lost+found"
                    ;;
                *)
                    echo "Ignoring $img"
                    continue
                    ;;
            esac

            [ -f "file_context-$PARTITION" ] && rm "file_context-$PARTITION"
            [ -f "fs_config-$PARTITION" ] && rm "fs_config-$PARTITION"
            for i in $($PREFIX find "tmp_out"); do
                {
                    echo -n "$i "
                    $PREFIX getfattr -n security.selinux --only-values -h "$i"
                    [ ! -z "$PREFIX" ] && sed 's/.$//'
                    echo ""
                } >> "file_context-$PARTITION"

                case "$i" in
                    *"run-as" | *"simpleperf_app_runner")
                        CAPABILITIES="0xc0"
                        ;;
                    *)
                        CAPABILITIES="0x0"
                        ;;
                esac
                echo "$($PREFIX stat -c "%n %u %g %a capabilities=$CAPABILITIES" "$i")" >> "fs_config-$PARTITION"
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

            $PREFIX umount "tmp_out"
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
    if [ ! -f "vbmeta.img" ] && tar tf "$BL_TAR" "vbmeta.img.lz4" &>/dev/null; then
        tar xf "$BL_TAR" "vbmeta.img.lz4" && lz4 -d --rm "vbmeta.img.lz4" "vbmeta.img"
    fi
    if [ ! -f "vbmeta_patched.img" ]; then
        cp --preserve=all "vbmeta.img" "vbmeta_patched.img"
        printf "\x03" | dd of="vbmeta_patched.img" bs=1 seek=123 count=1 conv=notrunc &> /dev/null
    fi

    cd "$PDR"
}

EXTRACT_ALL()
{
    BL_TAR=$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "BL*")
    AP_TAR=$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "AP*")

    mkdir -p "$FW_DIR/${MODEL}_${REGION}"
    EXTRACT_KERNEL_BINARIES
    EXTRACT_OS_PARTITIONS
    EXTRACT_AVB_BINARIES

    cp --preserve=all "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" "$FW_DIR/${MODEL}_${REGION}/.extracted"

    echo ""
}

FORCE=false
if [[ "$1" == "-f" ]] || [[ "$1" == "--force" ]]; then
    FORCE=true
elif [[ -n "$1" ]]; then
    echo "Unknown argument: \"$1\""
    exit 1
fi

source "$OUT_DIR/config.sh"

FIRMWARES=( "$SOURCE_FIRMWARE" "$TARGET_FIRMWARE" )
if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${TARGET_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
# ]

if [ "$#" -gt 0 ]; then
    echo "Usage: extract_fw"
    echo "This cmd does not accepts any arguments."
    exit 1
fi

mkdir -p "$FW_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)

    if [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
        if [ -f "$FW_DIR/${MODEL}_${REGION}/.extracted" ]; then
            if [[ "$(cat "$ODIN_DIR/${MODEL}_${REGION}/.downloaded")" != "$(cat "$FW_DIR/${MODEL}_${REGION}/.extracted")" ]]; then
                if $FORCE; then
                    echo "- Updating $MODEL firmware with $REGION CSC..."
                    rm -rf "$FW_DIR/${MODEL}_${REGION}" && EXTRACT_ALL
                else
                    echo    "- $MODEL firmware with $REGION CSC is already extracted."
                    echo    "  A newer version of this device's firmware is available."
                    echo -e "  To extract, clean your extracted firmwares directory or run this cmd with \"--force\"\n"
                    continue
                fi
            else
                echo -e "- $MODEL firmware with $REGION CSC is already extracted. Skipping...\n"
                continue
            fi
        else
            echo -e "- Extracting $MODEL firmware with $REGION CSC...\n"
            EXTRACT_ALL
        fi
    else
        echo -e "- $MODEL firmware with $REGION CSC is not downloaded. Skipping...\n"
        continue
    fi
done

exit 0
