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

# shellcheck disable=SC1091,SC2034,SC2046

set -o allexport

PACKAGES=(
  libbrotli-dev liblz4-dev libzstd-dev protobuf-compiler libgtest-dev
  ffmpeg webp zipalign clang build-essential cmake openjdk-17-jdk
  libncurses-dev bison flex libssl-dev libelf-dev python3
  python-is-python3 cpio attr zip libprotobuf-dev make
  libpcre2-dev ccache npm
)

echo "Checking dependencies..."

MISSING_PACKAGES=()
for PACKAGE in "${PACKAGES[@]}"; do
  if ! dpkg -s "$PACKAGE" >/dev/null 2>&1; then
    MISSING_PACKAGES+=("$PACKAGE")
  fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
  echo "All dependencies are already installed."
else
  echo "The following packages are missing: ${MISSING_PACKAGES[*]}"
  echo "Attempting to install missing packages..."
  sudo apt update
  sudo apt install "${MISSING_PACKAGES[@]}"
fi

echo "Checking for missing Git submodules..."

if [ -f .gitmodules ]; then
  UNINITIALIZED_SUBMODULES=$(git submodule status | grep '^-' || true)
  
  if [ -n "$UNINITIALIZED_SUBMODULES" ]; then
    echo "The following submodules are missing or uninitialized:"
    echo "$UNINITIALIZED_SUBMODULES"
    echo "Initializing and cloning submodules..."
    git submodule update --init --recursive
    if [ $? -eq 0 ]; then
      echo "Submodules initialized and cloned successfully."
    else
      echo "Failed to clone submodules. Please check your repository configuration."
      exit 1
    fi
  else
    echo "All submodules are already initialized."
  fi
else
  echo "No submodules found in this repository."
fi

#create venv if not exist
if [ ! -f "venv/bin/activate" ]; then
    echo "Virtual environment not found. Creating a new one..."
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

source venv/bin/activate

pip3 install git+https://github.com/ananjaser1211/samloader.git &> /dev/null


# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
TMP_DIR="$OUT_DIR/tmp"
ODIN_DIR="$OUT_DIR/odin"
FW_DIR="$OUT_DIR/fw"
APKTOOL_DIR="$OUT_DIR/apktool"
WORK_DIR="$OUT_DIR/work_dir"
TOOLS_DIR="$OUT_DIR/tools/bin"

PATH="$TOOLS_DIR:$PATH"

unica()
{
    local CMD=$1
    local CMDS
    CMDS="$(find "scripts" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | sed "s/.sh//g")"

    local YELLOW="\033[1;33m"
    local CYAN="\033[1;36m"
    local RESET_COLOR="\033[0m"

    if [ -z "$CMD" ] || [ "$CMD" = "-h" ]; then
        echo -e "Available cmds:"
        for script in "scripts"/*.sh; do
            CMD_NAME=$(basename "$script" .sh)
                        HELP_LINES=$(grep "^# CMD_HELP" "$script" | sed 's/^# CMD_HELP[[:space:]]*//')

            if [ -n "$HELP_LINES" ]; then
                echo -e "${YELLOW}$CMD_NAME${RESET_COLOR}:"
                echo -e "${CYAN}$HELP_LINES${RESET_COLOR}"
                echo ""
            else
                echo -e "${YELLOW}$CMD_NAME${RESET_COLOR} - No help available"
            fi
        done
        return 1
    elif ! echo "$CMDS" | grep -q -w "$CMD"; then
        echo "\"$CMD\" is not valid."
        echo -e "Available cmds:\n$CMDS"
        return 1
    else
        shift
        bash -e "$SRC_DIR/scripts/$CMD.sh" "$@"
    fi
}

# ]

TARGETS=($(ls "$SRC_DIR/target"))

if [ "$#" -ne 1 ]; then
    echo "Usage: source buildenv.sh <target>"
    echo "No target specified. Please choose from the available devices below:"

    select TARGET in "${TARGETS[@]}"; do
        if [ -n "$TARGET" ]; then
            echo "You selected: $TARGET"
            export SELECTED_TARGET="$TARGET"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    if [ -z "$SELECTED_TARGET" ]; then
        echo "No valid target selected. Exiting."
        return 1
    fi
else
    if ! printf "%s\n" "${TARGETS[@]}" | grep -q -w "$1"; then
        echo "\"$1\" is not a valid target."
        echo "Available devices:"
        printf "%s\n" "${TARGETS[@]}"
        return 1
    fi
    SELECTED_TARGET="$1"
fi

mkdir -p "$OUT_DIR"
unica build_dependencies || return 1

if [ -f "$OUT_DIR/config.sh" ]; then
    unset $(sed "/Automatically/d" "$OUT_DIR/config.sh" | cut -d= -f1)
fi

bash "$SRC_DIR/scripts/internal/gen_config_file.sh" "$SELECTED_TARGET" || return 1
source "$OUT_DIR/config.sh"

echo "=============================="
sed "/Automatically/d" "$OUT_DIR/config.sh"
echo "type "unica -h" for help"


return 0
