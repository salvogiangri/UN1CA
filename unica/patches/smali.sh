#====================================================
# FILE:         smali.sh
# AUTHOR:       BlackMesa123
# DESCRIPTION:  Read and applies all the ".patch"
#               files inside the "smali" folder to
#               the destination apk/jar.
#====================================================

# shellcheck disable=SC1091

set -Eeo pipefail

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"
APKTOOL_DIR="$OUT_DIR/apktool"

trap "echo 'Failed to apply'" ERR

APPLY_PATCHES()
{
    local TARGET="$1"
    local PATCHES

    if [ -d "$SRC_DIR/unica/patches/smali$TARGET" ]; then
        PATCHES+="$(find "$SRC_DIR/unica/patches/smali$TARGET" -type f -name "*.patch" -printf "%p ")"
    fi
    if [ -d "$SRC_DIR/target/$TARGET_CODENAME/patches/smali$TARGET" ]; then
        PATCHES+="$(find "$SRC_DIR/target/$TARGET_CODENAME/patches/smali$TARGET" -type f -name "*.patch" -printf "%p ")"
    fi

    [ ! -d "$APKTOOL_DIR$TARGET" ] && bash "$SRC_DIR/scripts/apktool.sh" d "$TARGET"

    cd "$APKTOOL_DIR$TARGET"
    for patch in $PATCHES; do
        local OUT
        local COMMIT_NAME
        COMMIT_NAME="$(grep "^Subject:" "$patch" | sed 's/.*PATCH] //')"

        if [[ "$patch" == *"0000-"* ]]; then
            [[ "$patch" == *"AOSP"* ]] && $ROM_IS_OFFICIAL && continue
            [[ "$patch" == *"UNICA"* ]] && $ROM_IS_OFFICIAL || continue
        fi

        echo "Applying \"$COMMIT_NAME\" to $TARGET"
        OUT="$(patch -p1 -s -t -N --dry-run < "$patch")" \
            || echo "$OUT" | grep -q "Skipping patch" || false
        patch -p1 -s -t -N < "$patch" &> /dev/null || true
    done
    cd - &> /dev/null

    bash "$SRC_DIR/scripts/apktool.sh" b "$TARGET"
}

source "$OUT_DIR/config.sh"
# ]

FILES_TO_PATCH="$(find "$SRC_DIR/unica/patches/smali" -type d \( -name "*.apk" -o -name "*.jar" \) -printf "%p\n" | sed 's/.*\/smali//')"
if [ -d "$SRC_DIR/target/$TARGET_CODENAME/patches/smali" ]; then
    FILES_TO_PATCH+="$(find "$SRC_DIR/target/$TARGET_CODENAME/patches/smali" -type d \( -name "*.apk" -o -name "*.jar" \) -printf "\n%p" | sed 's/.*\/smali//')"
fi
FILES_TO_PATCH="$(echo "$FILES_TO_PATCH" | tr " " "\n" | nl | sort -u -k2 | sort -n | cut -f2-)"

for i in $FILES_TO_PATCH; do
    APPLY_PATCHES "$i"
done

exit 0
