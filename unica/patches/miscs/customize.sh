SKIPUNZIP=1

# [
APPLY_PATCH()
{
    local PATCH
    local OUT

    DECOMPILE "$1"

    cd "$APKTOOL_DIR/$1"
    PATCH="$SRC_DIR/unica/patches/miscs/$2"
    OUT="$(patch -p1 -s -t -N --dry-run < "$PATCH")" \
        || echo "$OUT" | grep -q "Skipping patch" || false
    patch -p1 -s -t -N --no-backup-if-mismatch < "$PATCH" &> /dev/null || true
    cd - &> /dev/null
}

DECOMPILE()
{
    if [ ! -d "$APKTOOL_DIR/$1" ]; then
        bash "$SRC_DIR/scripts/apktool.sh" d "$1"
    fi
}

GET_PROP()
{
    local PROP="$1"
    local FILE="$2"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    grep "^$PROP=" "$FILE" | cut -d "=" -f2-
}

SET_PROP()
{
    local PROP="$1"
    local VALUE="$2"
    local FILE="$3"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        PROP="$(echo -n "$PROP" | sed 's/=//g')"
        if grep -Fq "$PROP" "$FILE"; then
            echo "Deleting \"$PROP\" prop in $FILE" | sed "s.$WORK_DIR..g"
            sed -i "/^$PROP/d" "$FILE"
        fi
    else
        if grep -Fq "$PROP" "$FILE"; then
            local LINES

            echo "Replacing \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            LINES="$(sed -n "/^${PROP}\b/=" "$FILE")"
            for l in $LINES; do
                sed -i "$l c${PROP}=${VALUE}" "$FILE"
            done
        else
            echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            if ! grep -q "Added by scripts" "$FILE"; then
                echo "# Added by scripts/internal/apply_modules.sh" >> "$FILE"
            fi
            echo "$PROP=$VALUE" >> "$FILE"
        fi
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

# Fix portrait mode
if [[ -f "$FW_DIR/${MODEL}_${REGION}/vendor/lib64/libDualCamBokehCapture.camera.samsung.so" ]]; then
    if grep -q "ro.build.flavor" "$FW_DIR/${MODEL}_${REGION}/vendor/lib64/libDualCamBokehCapture.camera.samsung.so"; then
        SET_PROP "ro.build.flavor" \
            "$(GET_PROP "ro.build.flavor" "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop")" \
            "$WORK_DIR/system/system/build.prop"
    elif grep -q "ro.product.name" "$FW_DIR/${MODEL}_${REGION}/vendor/lib64/libDualCamBokehCapture.camera.samsung.so"; then
        sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib/libDualCamBokehCapture.camera.samsung.so" && \
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib/liblivefocus_capture_engine.so" && \
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib/liblivefocus_preview_engine.so" && \
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib64/libDualCamBokehCapture.camera.samsung.so" && \
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib64/liblivefocus_capture_engine.so" && \
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib64/liblivefocus_preview_engine.so"
        echo -e "\nro.unica.camera u:object_r:build_prop:s0 exact string" >> "$WORK_DIR/system/system/etc/selinux/plat_property_contexts"
        SET_PROP "ro.unica.camera" \
            "$(GET_PROP "ro.product.system.name" "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop")" \
            "$WORK_DIR/system/system/build.prop"
    fi
fi

# Enable camera cutout protection
if [[ "$SOURCE_SUPPORT_CUTOUT_PROTECTION" != "$TARGET_SUPPORT_CUTOUT_PROTECTION" ]]; then
    DECOMPILE "system_ext/priv-app/SystemUI/SystemUI.apk"

    FTP="$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/res/values/bools.xml"
    R="\ \ \ \ <bool name=\"config_enableDisplayCutoutProtection\">$TARGET_SUPPORT_CUTOUT_PROTECTION</bool>"

    sed -i "$(sed -n "/config_enableDisplayCutoutProtection/=" "$FTP") c$R" "$FTP"
fi

#Get fingerprint sensor from floating_feature
DECOMPILE "system/framework/services.jar"

if [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    APPLY_PATCH "system/framework/services.jar" "fingerprint/qssi/services.jar/0001-Get-fingerprint-sensor-type-from-floating_feature.patch"
elif [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
    APPLY_PATCH "system/framework/services.jar" "fingerprint/essi/services.jar/0001-Get-fingerprint-sensor-type-from-floating_feature.patch"
fi
