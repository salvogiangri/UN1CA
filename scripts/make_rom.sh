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
START=$SECONDS

# [
COMMIT_HASH="$(git rev-parse HEAD)"
CONFIG_HASH="$(sed '/ROM_BUILD_TIMESTAMP/d' "$OUT_DIR/config.sh" | sha1sum | cut -d " " -f 1)"
WORK_DIR_HASH="$(echo -n "$COMMIT_HASH$CONFIG_HASH" | sha1sum | cut -d " " -f 1)"
# ]

FORCE=false
BUILD_ROM=false
BUILD_ZIP=false
BUILD_TAR=false

[[ "$TARGET_INSTALL_METHOD" == "zip" ]] && BUILD_ZIP=true
[[ "$TARGET_INSTALL_METHOD" == "odin" ]] && BUILD_TAR=true

while [ "$#" != 0 ]; do
    case "$1" in
        "-f" | "--force")
            FORCE=true
            ;;
        "--no-rom-zip")
            if $BUILD_TAR; then
                echo "TARGET_INSTALL_METHOD is \"odin\", ignoring --no-rom-zip"
            else
                BUILD_ZIP=false
            fi
            ;;
        "--no-rom-tar")
            if $BUILD_ZIP; then
                echo "TARGET_INSTALL_METHOD is \"zip\", ignoring --no-rom-tar"
            else
                BUILD_TAR=false
            fi
            ;;
        *)
            echo "Usage: make_rom [options]"
            echo " -f, --force : Force build"
            echo " --no-rom-zip : Do not build ROM zip"
            echo " --no-rom-tar : Do not build ROM tar"
            exit 1
            ;;
    esac

    shift
done

if [ -f "$WORK_DIR/.completed" ]; then
    if [[ "$(cat "$WORK_DIR/.completed")" != "$WORK_DIR_HASH" ]] && ! $FORCE; then
        echo "Changes in config.sh/the repo have been detected."
        echo "Please clean your work dir or run the cmd with \"--force\"."
        exit 1
    fi
else
    BUILD_ROM=true
fi

if $FORCE; then
    BUILD_ROM=true
fi

if $BUILD_ROM; then
    NEED_FW_DOWNLOAD=false
    bash "$SRC_DIR/scripts/extract_fw.sh" &> /dev/null || NEED_FW_DOWNLOAD=true
    if $NEED_FW_DOWNLOAD; then
        bash "$SRC_DIR/scripts/download_fw.sh"
        bash "$SRC_DIR/scripts/extract_fw.sh"
    fi

    echo -e "- Creating work dir..."
    bash "$SRC_DIR/scripts/internal/create_work_dir.sh"

    echo -e "\n- Applying debloat list..."
    bash "$SRC_DIR/scripts/internal/apply_debloat.sh"

    echo -e "\n- Applying ROM patches..."
    bash "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/patches"
    [[ -d "$SRC_DIR/target/$TARGET_CODENAME/patches" ]] \
        && bash "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/target/$TARGET_CODENAME/patches"

    echo -e "\n- Applying ROM mods..."
    bash "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods"

    echo -e "\n- Recompiling APKs/JARs..."
    while read -r i; do
        bash "$SRC_DIR/scripts/apktool.sh" b "$i"
    done <<< "$(find "$OUT_DIR/apktool" -type d \( -name "*.apk" -o -name "*.jar" \) -printf "%p\n" | sed "s.$OUT_DIR/apktool..")"

    echo ""
    echo -n "$WORK_DIR_HASH" > "$WORK_DIR/.completed"
else
    echo -e "- Nothing to do in work dir.\n"
fi

if $BUILD_ZIP; then
    echo "- Building ROM zip..."
    bash "$SRC_DIR/scripts/internal/build_flashable_zip.sh"
    echo ""
elif $BUILD_TAR; then
    echo "- Building ROM tar..."
    bash "$SRC_DIR/scripts/internal/build_odin_package.sh"
    echo ""
fi

ESTIMATED=$((SECONDS-START))
echo "Build completed in $((ESTIMATED / 3600))hrs $(((ESTIMATED / 60) % 60))min $((ESTIMATED % 60))sec."

exit 0
