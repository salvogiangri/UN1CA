# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Only the below variable(s) need to be changed!
VERSION_MAJOR=3
VERSION_MINOR=0
VERSION_PATCH=6

# The below variables will be generated automatically
#
# Version name
ROM_VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
# Append "+" to version name if commits have been added since the last tag
LATEST_TAG="$(git describe --tags --abbrev=0 2> /dev/null)"
if [ "$LATEST_TAG" ]; then
    if [[ "$(git rev-list --count "$LATEST_TAG...HEAD" 2> /dev/null)" =~ 0*[1-9][0-9]* ]]; then
        ROM_VERSION+="+"
    fi
fi
# Append current commit hash to version name
ROM_VERSION+="-$(git rev-parse --short HEAD 2> /dev/null || echo "null")"
# Append "-dirty" to version name if uncommited changes are detected
if [ "$(git --no-optional-locks status -uno --porcelain 2> /dev/null)" ]; then
    ROM_VERSION+="-dirty"
fi
