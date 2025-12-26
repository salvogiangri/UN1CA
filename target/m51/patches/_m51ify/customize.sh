LOG "- Patching a52q vendor with m51 vendor tree"

LOG_STEP_IN "- Removing a52q specific vendor blobs"

LOG_STEP_IN "- Removing init, soundbooster"
DELETE_FROM_WORK_DIR "vendor" "etc/init/hw/init.a52q.rc"
DELETE_FROM_WORK_DIR "vendor" "lib/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib/hw/audio.primary.atoll.so"
LOG_STEP_OUT

LOG_STEP_IN "- Removing sensor blobs"
REMOVAL_LIST="$(cd "$WORK_DIR/vendor/etc" 2>/dev/null && find sensors -type f -print 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/vendor/etc/$file" ] && DELETE_FROM_WORK_DIR "vendor" "etc/$file"
done <<< "$REMOVAL_LIST"
LOG_STEP_OUT

LOG_STEP_IN "- Removing audconf blobs"
REMOVAL_LIST="$(cd "$WORK_DIR/vendor/etc" 2>/dev/null && find audconf -type f -print 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/vendor/etc/$file" ] && DELETE_FROM_WORK_DIR "vendor" "etc/$file"
done <<< "$REMOVAL_LIST"
LOG_STEP_OUT

LOG_STEP_IN "- Removing camera libraries"
REMOVAL_LIST="$(find "$WORK_DIR/vendor" -type f -path '*/lib*/camera/*' -printf '%P\n' 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/vendor/$file" ] && DELETE_FROM_WORK_DIR "vendor" "$file"
done <<< "$REMOVAL_LIST"
LOG_STEP_OUT

LOG_STEP_OUT 

LOG_STEP_IN "- Patching a52q properties with m51"
SET_PROP "vendor" "ro.product.board" "sm6150"
SET_PROP "vendor" "ro.board.platform" "sm6150"
SET_PROP "vendor" "ro.hardware.chipname" "SM7150"
SET_PROP "vendor" "ro.soc.model" "SM7150"
SET_PROP "vendor" "ro.vendor.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "vendor" "ro.vendor.build.version.incremental" "M515FXXS6DXE4"
SET_PROP "vendor" "ro.product.vendor.device" "m51"
SET_PROP "vendor" "ro.product.vendor.model" "SM-M515F"
SET_PROP "vendor" "ro.product.vendor.name" "m51nsxx"
SET_PROP "vendor" "ro.bootimage.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "odm" "ro.odm.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "odm" "ro.odm.build.version.incremental" "M515FXXS6DXE4"
SET_PROP "odm" "ro.product.odm.device" "m51"
SET_PROP "odm" "ro.product.odm.model" "SM-M515F"
SET_PROP "odm" "ro.product.odm.name" "m51nsxx"
LOG_STEP_OUT

LOG_STEP_IN "- Running hex patches for atoll -> sm6150"
find "$WORK_DIR/vendor" -type f -name '*atoll*' -print0 2>/dev/null |
 while IFS= read -r -d '' f; do
   HEX_PATCH "$f" "61746F6C6C2E736F00" "736D363135302E736F"
   mv -- "$f" "$(printf '%s' "$f" | sed 's/atoll/sm6150/g')" 2>/dev/null
 done
LOG_STEP_OUT

LOG_STEP_IN "- Replacing a52q props with m51"
sed -i -e 's|sm7125|sm7150|g' -e 's|a52q|m51|g' -e 's|A52|M51|g' "$WORK_DIR/vendor/etc/floating_feature.xml"
sed -i 's|a52q|m51|g' "$WORK_DIR/vendor/etc/ev_lux_map_config.xml" "$WORK_DIR/vendor/etc/sensorhub_services.json"
sed -i 's|A52|M51|g' "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
sed -i 's|atoll|sm6150|g' "$WORK_DIR/vendor/etc/vramdiskd.xml" "$WORK_DIR/configs/file_context-vendor" "$WORK_DIR/configs/fs_config-vendor"
LOG_STEP_OUT

LOG_STEP_IN "- Adding media profiles into odm from vendor"
cp -a "$WORK_DIR/vendor/etc/media_profiles_V1_0.xml" "$WORK_DIR/odm/etc"
LOG_STEP_OUT

LOG_STEP_IN "- Performing additional steps before applying the next patches"
TARGET_FIRMWARE_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
cp -r "$WORK_DIR/vendor/build.prop" "$TARGET_FIRMWARE_DEST/vendor"
LOG_STEP_OUT 

LOG "- M51IFY has been completed successfully"

unset REMOVAL_LIST TARGET_FIRMWARE_DEST