SKIPUNZIP=1

SET_CONFIG()
{
    local CONFIG="$1"
    local VALUE="$2"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        CONFIG="$(echo -n "$CONFIG" | sed 's/=//g')"
        if grep -Fq "$CONFIG" "$FILE"; then
            echo "Deleting \"$CONFIG\" config in /system/system/etc/floating_feature.xml"
            sed -i "/$CONFIG/d" "$FILE"
        fi
    else
        if grep -Fq "<$CONFIG>" "$FILE"; then
            echo "Replacing \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
            sed -i "$(sed -n "/<${CONFIG}>/=" "$FILE") c\ \ \ \ <${CONFIG}>${VALUE}</${CONFIG}>" "$FILE"
        else
            echo "Adding \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
            sed -i "/<\/SecFloatingFeatureSet>/d" "$FILE"
            if ! grep -q "Added by unica" "$FILE"; then
                echo "    <!-- Added by unica/patches/floating_feature/customize.sh -->" >> "$FILE"
            fi
            echo "    <${CONFIG}>${VALUE}</${CONFIG}>" >> "$FILE"
            echo "</SecFloatingFeatureSet>" >> "$FILE"
        fi
    fi
}

READ_AND_APPLY_CONFIGS()
{
    local CONFIG_FILE="$SRC_DIR/target/$TARGET_CODENAME/sff.sh"

    if [ -f "$CONFIG_FILE" ]; then
        while read -r i; do
            [[ "$i" = "#"* ]] && continue
            [[ -z "$i" ]] && continue

            if [[ "$i" == *"delete" ]] || [[ -z "$(echo -n "$i" | cut -d "=" -f 2)" ]]; then
                SET_CONFIG "$(echo -n "$i" | cut -d " " -f 1)" --delete
            elif echo -n "$i" | grep -q "="; then
                SET_CONFIG "$(echo -n "$i" | cut -d "=" -f 1)" "$(echo -n "$i" | cut -d "=" -f2-)"
            else
                echo "Malformed string in target/$TARGET_CODENAME/sff.sh: \"$i\""
                return 1
            fi
        done < "$CONFIG_FILE"
    fi
}

# Apply target floating feature
READ_AND_APPLY_CONFIGS

# mDNIe
if $SOURCE_HAS_HW_MDNIE; then
    if ! $TARGET_HAS_HW_MDNIE; then
        SET_CONFIG "SEC_FLOATING_FEATURE_LCD_SUPPORT_MDNIE_HW" --delete
    fi
fi

# eSIM
if $SOURCE_IS_ESIM_SUPPORTED; then
    if ! $TARGET_IS_ESIM_SUPPORTED; then
        SET_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" --delete
        SET_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_EMBEDDED_SIM" --delete
    fi
fi

# Smart Tutor
SET_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_SMARTTUTOR_PACKAGES_PATH" --delete

# Logging
SET_CONFIG "SEC_FLOATING_FEATURE_CONTEXTSERVICE_ENABLE_SURVEY_MODE" --delete
