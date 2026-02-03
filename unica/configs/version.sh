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
