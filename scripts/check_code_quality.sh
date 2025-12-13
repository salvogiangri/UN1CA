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

# Script to check code quality of shell scripts in the project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "==================================="
echo "UN1CA Code Quality Check"
echo "==================================="
echo ""

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo "ERROR: shellcheck is not installed"
    echo "Please install shellcheck to run code quality checks"
    echo ""
    echo "Installation:"
    echo "  Ubuntu/Debian: sudo apt-get install shellcheck"
    echo "  macOS: brew install shellcheck"
    echo "  Arch Linux: sudo pacman -S shellcheck"
    exit 1
fi

echo "Checking shell scripts..."
echo ""

# Run shellcheck on all scripts
ERRORS=0
if ! find scripts -name "*.sh" -type f -print0 | xargs -0 shellcheck -S warning; then
    ERRORS=1
fi

echo ""
echo "==================================="
echo "Summary"
echo "==================================="

if [ "$ERRORS" -eq 0 ]; then
    echo "✅ Code quality check PASSED"
    exit 0
else
    echo "❌ Code quality check FAILED"
    exit 1
fi
