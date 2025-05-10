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

VERSION_MAJOR=2
VERSION_MINOR=5
VERSION_PATCH=6

ROM_VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
# Append current commit hash to version name
ROM_VERSION+="-$(git rev-parse --short HEAD)"

# Match latest Samsung's flagship device codename
# - 1.x.x: Diamond (S23)
# - 2.x.x: Eureka (S24)
ROM_CODENAME="Eureka"
