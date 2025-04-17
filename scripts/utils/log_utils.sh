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
_GET_CALLER_INFO()
{
    if [ "${FUNCNAME[2]}" ]; then
        echo -n "("
        if [ "${BASH_SOURCE[3]}" ]; then
            echo -n "${BASH_SOURCE[3]//$SRC_DIR\//}:"
        fi
        if [ "${BASH_LINENO[2]}" ]; then
            echo -n "${BASH_LINENO[2]}:"
        fi
        echo -n "${FUNCNAME[2]}) "
    fi
}
# ]

# LOG <message>
# Prints a log message in the build output.
LOG()
{
    echo -e "$1"
}

# LOGE <message>
# Prints an error log message in the build output.
LOGE()
{
    local RED
    local RESET
    RED="$(tput setaf 1)"
    RESET="$(tput sgr0)"

    echo -e "${RED}$(_GET_CALLER_INFO)${1}${RESET}" >&2
}

# LOGW <message>
# Prints a warning log message in the build output.
LOGW()
{
    local YELLOW
    local RESET
    YELLOW="$(tput setaf 3)"
    RESET="$(tput sgr0)"

    echo -e "${YELLOW}$(_GET_CALLER_INFO)${1}${RESET}" >&2
}
