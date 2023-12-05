SKIPUNZIP=1

set -Eeo pipefail

trap "echo 'Failed to apply'" ERR

APPLY_PATCHES()
{
    local TARGET="$1"

    local PATCHES="$(find "$SRC_DIR/target/$TARGET_CODENAME/patches/smali$TARGET" -type f -name "*.patch" -printf "%p ")"

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
}

FILES_TO_PATCH+="$(find "$SRC_DIR/target/$TARGET_CODENAME/patches/smali" -type d \( -name "*.apk" -o -name "*.jar" \) -printf "\n%p" | sed 's/.*\/smali//')"
for i in $FILES_TO_PATCH; do
    APPLY_PATCHES "$i"
done
