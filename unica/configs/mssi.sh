# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# UN1CA configuration file for MediaTek devices (mssi)

# Inherit source firmware configuration from essi
source "$SRC_DIR/unica/configs/essi.sh" || return 1

# Galaxy M53 5G (One UI 8.0)
SOURCE_EXTRA_FIRMWARES=("SM-M536B/EUX/351069501234561")
SOURCE_SUPER_GROUP_NAME="main"
