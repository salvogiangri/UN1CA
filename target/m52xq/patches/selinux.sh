#====================================================
# FILE:         selinux.sh
# AUTHOR:       ShaDisNX255
# DESCRIPTION:  Remove unsupported sepolicy entries
#====================================================

# shellcheck disable=SC1091

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
WORK_DIR="$OUT_DIR/work_dir"
# ]

echo "Applying SELinux patches"
sed -i "/fabriccrypto/d" "$WORK_DIR/system/system/system_ext/etc/selinux/mapping/30.0.cil"

exit 0
