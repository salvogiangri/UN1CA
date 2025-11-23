#!/usr/bin/env bash
#
# Copyright (C) 2025 Salvo Giangreco
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

# [
source "$SRC_DIR/scripts/utils/log_utils.sh" || exit 1

GENERATE_VERSION_INFO()
{
    echo "# External tool versions"
    echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo ""
    
    cd "$SRC_DIR/external/android-tools" || exit 1
    echo "android-tools=$(git rev-parse HEAD)"
    
    cd "$SRC_DIR/external/apktool" || exit 1
    echo "apktool=$(git rev-parse HEAD)"
    
    cd "$SRC_DIR/external/erofs-utils" || exit 1
    echo "erofs-utils=$(git rev-parse HEAD)"
    
    cd "$SRC_DIR/external/img2sdat" || exit 1
    echo "img2sdat=$(git rev-parse HEAD)"
    
    cd "$SRC_DIR/external/samloader" || exit 1
    echo "samloader=$(git rev-parse HEAD)"
    
    cd "$SRC_DIR/external/signapk" || exit 1
    echo "signapk=$(git rev-parse HEAD)"
}

COPY_TOOLS()
{
    local TOOLS_BIN="$OUT_DIR/tools/bin"
    local PREBUILTS_DIR="$SRC_DIR/prebuilts/external"

    if [ ! -d "$TOOLS_BIN" ]; then
        LOGE "Tools directory not found: ${TOOLS_BIN//$SRC_DIR\//}"
        LOGE "Please run build_dependencies.sh first"
        exit 1
    fi

    LOG "- Copying tools to prebuilts/external"

    # Create prebuilts directory structure
    mkdir -p "$PREBUILTS_DIR/bin"
    mkdir -p "$PREBUILTS_DIR/venv"

    # Copy all binaries from tools/bin, excluding .git files/directories
    rsync -a --exclude='.git' "$TOOLS_BIN/" "$PREBUILTS_DIR/bin/" || exit 1

    # Copy venv for samloader, excluding .git files/directories
    if [ -d "$OUT_DIR/tools/venv" ]; then
        rsync -a --exclude='.git' "$OUT_DIR/tools/venv/" "$PREBUILTS_DIR/venv/" || exit 1
    fi

    # Make all executables in bin directory executable
    find "$PREBUILTS_DIR/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
    
    # Remove any .git files/directories that may have been copied
    find "$PREBUILTS_DIR" -name ".git" -print0 2>/dev/null | xargs -0 rm -rf 2>/dev/null || true
}

RECORD_VERSIONS()
{
    local PREBUILTS_DIR="$SRC_DIR/prebuilts/external"
    local VERSION_FILE="$PREBUILTS_DIR/.current"

    LOG "- Recording tool versions"

    GENERATE_VERSION_INFO > "$VERSION_FILE"
}

CHECK_CHANGES()
{
    local PREBUILTS_DIR="$SRC_DIR/prebuilts/external"
    local VERSION_FILE="$PREBUILTS_DIR/.current"
    local TEMP_VERSION_FILE="/tmp/prebuilt_tools_versions.tmp"

    if [ ! -f "$VERSION_FILE" ]; then
        # First time running, versions file doesn't exist
        return 1
    fi

    # Generate current versions to temp file
    GENERATE_VERSION_INFO > "$TEMP_VERSION_FILE"

    # Compare versions (ignoring date lines)
    if diff <(grep -v "^#" "$VERSION_FILE") <(grep -v "^#" "$TEMP_VERSION_FILE") >/dev/null 2>&1; then
        # No changes
        rm -f "$TEMP_VERSION_FILE"
        return 0
    else
        # Changes detected
        rm -f "$TEMP_VERSION_FILE"
        return 1
    fi
}
# ]

if [[ "$#" != "0" ]]; then
    echo "Usage: update_prebuilt_tools" >&2
    echo "This script does not accept any arguments." >&2
    exit 1
fi

LOG_STEP_IN true "Starting update_prebuilt_tools"

# Check if there are any changes
if CHECK_CHANGES; then
    LOG "\033[0;33m! No version changes detected. Nothing to do.\033[0m"
    exit 0
fi

LOG "- External tool versions have changed"
LOG_STEP_OUT

LOG_STEP_IN true "Copying built tools to prebuilts"
COPY_TOOLS || exit 1
LOG_STEP_OUT

LOG_STEP_IN true "Recording version information"
RECORD_VERSIONS || exit 1

exit 0
