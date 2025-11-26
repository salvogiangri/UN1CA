if [[ "$TARGET_CODENAME" = "m51" ]]; then
SKIPUNZIP=1
# [
ADD_TO_WORK_DIR_CONTEXT()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ] || [ -L "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

GET_PROPS()
{
    local PROP="$1"
    local FILE="$2"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    grep "^$PROP=" "$FILE" | cut -d "=" -f2-
}

SET_PROPS()
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

LOG "M51 System Adaptor"

# We wipe the A52 blobs we don't need
LOG "Removing A52 blobs"
#fstab, init, soundbooster 
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/fstab.default"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/fstab.emmc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/init/hw/init.a52q.rc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/lib_SoundBooster_ver1050.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/lib_SoundBooster_ver1050.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/audio.primary.atoll.so"

#Sensors
DEBLOAT_LIST="$(cd "$WORK_DIR/vendor/etc" 2>/dev/null && find sensors -type f -print 2>/dev/null | sort || true)"

while IFS= read -r file; do
    [ -z "$file" ] && continue
    REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/$file"
done <<< "$DEBLOAT_LIST"

#Camera
DEBLOAT_LIST="$(find "$WORK_DIR/vendor/lib" "$WORK_DIR/vendor/lib64" -type f -path '*/camera/*' -printf '%P\n' 2>/dev/null | sort || true)"

while IFS= read -r file; do
    [ -z "$file" ] && continue
    REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor"/lib*/"$file"
done <<< "$DEBLOAT_LIST"

# Copy M51 blobs
LOG "Installing M51 drivers"
cp -a "$SRC_DIR/unica/patches/__m51ify/M515F/." "$WORK_DIR/"

# SELinux and prop config
LOG "Configuring properties"
CONTEXTS_LIST="$(cd "$SRC_DIR/unica/patches/__m51ify/M515F/vendor" 2>/dev/null && find lib lib64 -type f -print 2>/dev/null | sort || true)"

while IFS= read -r context; do
    [ -z "$context" ] && continue
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 2000 644 "u:object_r:vendor_lib_file:s0"
done <<< "$CONTEXTS_LIST"

CONTEXTS_LIST="$(cd "$SRC_DIR/unica/patches/__m51ify/M515F/vendor" 2>/dev/null && find etc -type f -print 2>/dev/null | sort || true)"

while IFS= read -r context; do
    [ -z "$context" ] && continue
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 0 644 "u:object_r:vendor_configs_file:s0"
done <<< "$CONTEXTS_LIST"

CONTEXTS_LIST="$(cd "$SRC_DIR/unica/patches/__m51ify/M515F/vendor" 2>/dev/null && find firmware -type f -print 2>/dev/null | sort || true)"

while IFS= read -r context; do
    [ -z "$context" ] && continue
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 0 644 "u:object_r:vendor_firmware_file:s0"
done <<< "$CONTEXTS_LIST"

ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/android.hardware.gnss@2.1-service-qti" 0 2000 755 "u:object_r:vendor_hal_gnss_qti_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/xtra-daemon" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/loc_launcher" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/lowi-server" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/android.hardware.drm@1.3-service.clearkey" 0 2000 755 "u:object_r:vendor_hal_drm_clearkey_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/android.hardware.drm@1.3-service.widevine" 0 2000 755 "u:object_r:vendor_hal_drm_widevine_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/vendor.samsung.hardware.camera.provider@4.0-service" 0 2000 755 "u:object_r:hal_camera_default_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/wvkprov" 0 2000 755 "u:object_r:wvkprov_exec:s0"

ADD_TO_WORK_DIR_CONTEXT "vendor" "overlay/framework-res__auto_generated_rro_vendor.apk" 0 2000 755 "u:object_r:vendor_file:s0"

CONTEXTS_LIST="$(cd "$SRC_DIR/unica/patches/__m51ify/M515F/vendor" 2>/dev/null && find etc/audconf -type d -print 2>/dev/null | sort || true)"

while IFS= read -r context; do
    [ -z "$context" ] && continue
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 2000 755 "u:object_r:vendor_configs_file:s0"
done <<< "$CONTEXTS_LIST"

LOG_STEP_IN "Patching a52q properties for m51"
SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
SET_PROPS "VE" "$(GET_PROPS "VE" "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/etc/selinux/vendor_sepolicy_version")" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
SET_PROPS "BD" "$(GET_PROPS "BD" "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/etc/selinux/vendor_sepolicy_version")" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
SET_PROP "vendor" "ro.product.board" "sm6150"
SET_PROP "vendor" "ro.board.platform" "sm6150"
SET_PROP "vendor" "ro.vendor.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "vendor" "ro.vendor.build.version.incremental" "M515FXXS6DXE4"
SET_PROP "vendor" "ro.product.vendor.device" "m51"
SET_PROP "vendor" "ro.product.vendor.model" "SM-M515F"
SET_PROP "vendor" "ro.product.vendor.name" "m51nsxx"
SET_PROP "vendor" "ro.bootimage.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
# XML / json replacements
sed -i -e 's|siop_a52q_sm7125|siop_m51_sm7150|g' \
       -e 's|a52q|m51|g' \
       -e 's|A52|M51|g' "$WORK_DIR/vendor/etc/floating_feature.xml"

sed -i 's|a52q|m51|g' "$WORK_DIR/vendor/etc/ev_lux_map_config.xml"
sed -i 's|a52q|m51|g' "$WORK_DIR/vendor/etc/sensorhub_services.json"

# Patch binaries that contain "atoll.so" and then rename files containing "atoll"
find "$WORK_DIR/vendor" -type f -name '*atoll*' -print0 |
 while IFS= read -r -d '' f; do
   HEX_PATCH "$f" 61746f6c6c2e736f00 736d363135302e736f
   mv -- "$f" "$(printf '%s' "$f" | sed 's/atoll/sm6150/g')" 2>/dev/null
 done

# Text replacements in other config files
sed -i 's|atoll|sm6150|g' "$WORK_DIR/vendor/etc/vramdiskd.xml"
sed -i 's|atoll|sm6150|g' "$WORK_DIR/configs/file_context-vendor"
sed -i 's|atoll|sm6150|g' "$WORK_DIR/configs/fs_config-vendor"
LOG_STEP_OUT 

LOG "Patching media_profiles_V1_0.xml on odm"
cp -r $WORK_DIR/vendor/etc/media_profiles_V1_0.xml $WORK_DIR/odm/etc

LOG "Patching selinux"
ADD_TO_WORK_DIR "system_ext" "etc/selinux/mapping/30.0.cil"

LOG "m51ify has been completed successfully!"

else
    LOG "\033[0;33m! Nothing to do\033[0m"
    return 0
fi
