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

# shellcheck disable=SC2162

# CMD_HELP Extracts downloaded Firmware

set -e

# [
GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$REGION/$MODEL/version.xml" \
        | grep latest | sed 's/^[^>]*>//' | sed 's/<.*//'
}

GET_IMG_FS_TYPE()
{
    if [[ "$(xxd -p -l "2" --skip "1080" "$1")" == "53ef" ]]; then
        echo "ext4"
    elif [[ "$(xxd -p -l "4" --skip "1024" "$1")" == "1020f5f2" ]]; then
        echo "f2fs"
    elif [[ "$(xxd -p -l "4" --skip "1024" "$1")" == "e2e1f5e0" ]]; then
        echo "erofs"
    else
        echo "unknown"
    fi
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
        echo "Extracting ${file%.lz4}"
        tar xf "$AP_TAR" "$file" && lz4 -d -q --rm "$file" "${file%.lz4}"
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
            echo "Extracting super.img"
            tar xf "$AP_TAR" "super.img.lz4"
            lz4 -d -q --rm "super.img.lz4" "super.img.sparse"
            simg2img "super.img.sparse" "super.img" && rm "super.img.sparse"
            { lpunpack "super.img" > /dev/null; } 2>&1
            lpdump "super.img" > "lpdump" && rm "super.img"
        fi

        [ -d "tmp_out" ] && mountpoint -q "tmp_out" && sudo umount "tmp_out"
        mkdir -p "tmp_out"
        for img in *.img
        do
            local PREFIX=""
            local PARTITION="${img%.img}"

            case "$(GET_IMG_FS_TYPE "$img")" in
                "erofs")
                    echo "Extracting $img"
                    PREFIX=""
                    [ -d "$PARTITION" ] && rm -rf "$PARTITION"
                    mkdir -p "$PARTITION"
                    fuse.erofs "$img" "tmp_out" &>/dev/null
                    cp -a --preserve=all tmp_out/* "$PARTITION"
                    ;;
                "f2fs" | "ext4")
                    echo "Extracting $img"
                    PREFIX="sudo"
                    [ -d "$PARTITION" ] && rm -rf "$PARTITION"
                    mkdir -p "$PARTITION"
                    $PREFIX mount -o ro "$img" "tmp_out"
                    $PREFIX cp -a --preserve=all tmp_out/* "$PARTITION"
                    for i in $($PREFIX find "$PARTITION"); do
                        $PREFIX chown -h "$(whoami)":"$(whoami)" "$i"
                    done
                    [[ -e "$PARTITION/lost+found" ]] && rm -rf "$PARTITION/lost+found"
                    ;;
                *)
                    continue
                    ;;
            esac

            echo "Generating fs_config/file_context for $img"
            [ -f "file_context-$PARTITION" ] && rm "file_context-$PARTITION"
            [ -f "fs_config-$PARTITION" ] && rm "fs_config-$PARTITION"
            while read -r i; do
                {
                    echo -n "$i "
                    $PREFIX getfattr -n security.selinux --only-values -h "$i"
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
                $PREFIX stat -c "%n %u %g %a capabilities=$CAPABILITIES" "$i" >> "fs_config-$PARTITION"
            done <<< "$($PREFIX find "tmp_out")"
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
            sed -i "s/\x0//g" "file_context-$PARTITION" \
                && sed -i 's/\./\\./g' "file_context-$PARTITION" \
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
        echo "Extracting vbmeta.img"
        tar xf "$BL_TAR" "vbmeta.img.lz4" && lz4 -d -q --rm "vbmeta.img.lz4" "vbmeta.img"
    fi
    if [ ! -f "vbmeta_patched.img" ]; then
        echo "Generating vbmeta_patched.img"
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

FIRMWARES=( "$SOURCE_FIRMWARE" "$TARGET_FIRMWARE" )
IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${SOURCE_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
IFS=':' read -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${TARGET_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
# ]

FORCE=false

while [ "$#" != 0 ]; do
    case "$1" in
        "-f" | "--force")
            FORCE=true
            ;;
        *)
            echo "Usage: extract_fw [options]"
            echo " -f, --force : Force firmware extraction"
            exit 1
            ;;
    esac

    shift
done

mkdir -p "$FW_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)

    if [ -f "$FW_DIR/${MODEL}_${REGION}/.extracted" ]; then
        [ -z "$(GET_LATEST_FIRMWARE)" ] && continue
        if [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ] && \
            [[ "$(cat "$ODIN_DIR/${MODEL}_${REGION}/.downloaded")" != "$(cat "$FW_DIR/${MODEL}_${REGION}/.extracted")" ]]; then
            if $FORCE; then
                echo "- Updating $MODEL firmware with $REGION CSC..."
                rm -rf "$FW_DIR/${MODEL}_${REGION}" && EXTRACT_ALL
            else
                echo    "- $MODEL firmware with $REGION CSC is already extracted."
                echo    "  A newer version of this device's firmware is available."
                echo -e "  To extract, clean your extracted firmwares directory or run this cmd with \"--force\"\n"
                continue
            fi
        elif [[ "$(GET_LATEST_FIRMWARE)" != "$(cat "$FW_DIR/${MODEL}_${REGION}/.extracted")" ]]; then
            echo    "- $MODEL firmware with $REGION CSC is already extracted."
            echo    "  A newer version of this device's firmware is available."
            echo -e "  Please download the firmware using the \"download_fw\" cmd\n"
            continue
        else
            echo -e "- $MODEL firmware with $REGION CSC is already extracted. Skipping...\n"
            continue
        fi
    elif [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
        echo -e "- Extracting $MODEL firmware with $REGION CSC...\n"
        EXTRACT_ALL
    else
        echo    "- $MODEL firmware with $REGION CSC is not downloaded."
        echo -e "  Please download the firmware first using the \"download_fw\" cmd\n"
        exit 1
    fi
done

exit 0
