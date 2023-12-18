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

# shellcheck disable=SC1091

set -Eeuo pipefail
START=$SECONDS

# [
COMMIT_HASH="$(git rev-parse HEAD)"
CONFIG_HASH="$(sha1sum "$OUT_DIR/config.sh" | cut -d " " -f 1)"
WORK_DIR_HASH="$(echo -n "$COMMIT_HASH$CONFIG_HASH" | sha1sum | cut -d " " -f 1)"
# ]

FORCE=false
BUILD_ROM=false
BUILD_ZIP=true

while [ "$#" != 0 ]; do
    case "$1" in
        "-f" | "--force")
            FORCE=true
            ;;
        "--no-rom-zip")
            BUILD_ZIP=false
            ;;
        *)
            echo "Usage: make_rom [options]"
            echo " -f, --force : Force build"
            echo " --no-rom-zip : Do not build ROM zip"
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
    bash "$SRC_DIR/scripts/extract_fw.sh"

    echo -e "- Creating work dir..."
    bash "$SRC_DIR/scripts/internal/create_work_dir.sh"

    echo -e "\n- Applying debloat list..."
    bash "$SRC_DIR/scripts/internal/apply_debloat.sh"

    echo -e "\n- Applying ROM packages..."
    bash "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/packages"

    echo -e "\n- Applying ROM patches..."
    bash "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/patches"
    [[ -d "$SRC_DIR/target/$TARGET_CODENAME/patches" ]] \
        && bash "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/target/$TARGET_CODENAME/patches"

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
fi

ESTIMATED=$((SECONDS-START))
echo "Build completed in $((ESTIMATED / 3600))hrs $(((ESTIMATED / 60) % 60))min $((ESTIMATED % 60))sec."

exit 0
