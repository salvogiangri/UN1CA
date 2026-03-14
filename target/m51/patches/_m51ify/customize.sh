SET_PROP_INTO_FILE() 
{
  local f="$1" p="$2" v="$3"
  [ -f "$f" ] || return 1
  if [ "$v" = "-d" ]; then
    sed -i "/^$p=/d" "$f"
  elif grep -q "^$p=" "$f"; then
    sed -i "s|^$p=.*|$p=$v|" "$f"
  else
    grep -q "Added by" "$f" || echo "# Added by scripts" >> "$f"
    echo "$p=$v" >> "$f"
  fi
}

LOG "- Patching a52q firmware with m51 device tree"

LOG_STEP_IN "- Cleaning up a52q-specific proprietary blobs"

LOG_STEP_IN "- Removing a52q init script, soundbooster, audio configuration and lux mapping"
DELETE_FROM_WORK_DIR "vendor" "etc/init/hw/init.a52q.rc"
DELETE_FROM_WORK_DIR "system" "system/lib/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib/hw/audio.primary.atoll.so"
DELETE_FROM_WORK_DIR "vendor" "etc/audconf/ODM"
DELETE_FROM_WORK_DIR "vendor" "etc/ev_lux_map_config.xml"
LOG_STEP_OUT

LOG_STEP_IN "- Purging sensor configuration files"
REMOVAL_LIST="$(cd "$WORK_DIR/vendor/etc" 2>/dev/null && find sensors -type f -print 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/vendor/etc/$file" ] && DELETE_FROM_WORK_DIR "vendor" "etc/$file"
done <<< "$REMOVAL_LIST"
LOG_STEP_OUT

LOG_STEP_IN "- Stripping camera libraries"
REMOVAL_LIST="$(find "$WORK_DIR/vendor" -type f -path '*/lib*/camera/*' -printf '%P\n' 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/vendor/$file" ] && DELETE_FROM_WORK_DIR "vendor" "$file"
done <<< "$REMOVAL_LIST"
LOG_STEP_OUT

LOG_STEP_OUT 

LOG_STEP_IN "- Overriding a52q properties with m51 values"
SET_PROP "vendor" "ro.product.board" "sm6150"
SET_PROP "vendor" "ro.board.platform" "sm6150"
SET_PROP "vendor" "ro.hardware.chipname" "SM7150"
SET_PROP "vendor" "ro.soc.model" "SM7150"
SET_PROP "vendor" "ro.vendor.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "vendor" "ro.vendor.build.version.incremental" "M515FXXS6DXE4"
SET_PROP "vendor" "ro.product.vendor.device" "m51"
SET_PROP "vendor" "ro.product.vendor.model" "SM-M515F"
SET_PROP "vendor" "ro.product.vendor.name" "m51nsxx"
SET_PROP "vendor" "ro.netflix.bsp_rev" "Q7250-19133-1"
SET_PROP "vendor" "ro.bootimage.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "odm" "ro.odm.build.fingerprint" "samsung/m51nsxx/m51:11/RP1A.200720.012/M515FXXS6DXE4:user/release-keys"
SET_PROP "odm" "ro.odm.build.version.incremental" "M515FXXS6DXE4"
SET_PROP "odm" "ro.product.odm.device" "m51"
SET_PROP "odm" "ro.product.odm.model" "SM-M515F"
SET_PROP "odm" "ro.product.odm.name" "m51nsxx"
SET_PROP "product" "ro.product.product.name" "m51nsxx"
LOG_STEP_OUT

LOG_STEP_IN "- Applying hex patches for atoll -> sm6150"
find "$WORK_DIR/vendor" -type f -name '*atoll*' -print0 2>/dev/null |
 while IFS= read -r -d '' f; do
   HEX_PATCH "$f" "61746F6C6C2E736F00" "736D363135302E736F"
   EVAL "mv -- \"$f\" \"$(printf '%s' \"$f\" | sed 's/atoll/sm6150/g')\""
 done
LOG_STEP_OUT

LOG_STEP_IN "- Replacing a52q string references in config files"
EVAL "sed -i -e 's|sm7125|sm7150|g' -e 's|a52q|m51|g' -e 's|A52|M51|g' \"$WORK_DIR/vendor/etc/floating_feature.xml\""
EVAL "sed -i 's|a52q|m51|g' \"$WORK_DIR/vendor/etc/sensorhub_services.json\""
EVAL "sed -i 's|A52|M51|g' \"$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version\""
EVAL "sed -i 's|atoll|sm6150|g' \"$WORK_DIR/vendor/etc/vramdiskd.xml\" \"$WORK_DIR/configs/file_context-vendor\" \"$WORK_DIR/configs/fs_config-vendor\""
LOG_STEP_OUT

LOG_STEP_IN "- Injecting m51-specific blobs"
EVAL "git clone \"https://github.com/mehedihjoy0/M51-Device-Tree\" \"$MODPATH/tree\""
ADD_TO_WORK_DIR "$MODPATH/tree" "system" "."
ADD_TO_WORK_DIR "$MODPATH/tree" "vendor" "."
EVAL "cp -r \"$WORK_DIR/vendor/etc/media_profiles_V1_0.xml\" \"$WORK_DIR/odm/etc\""
LOG_STEP_OUT

LOG_STEP_IN "- Performing additional steps before going to the next step"
TARGET_FIRMWARE_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
EVAL "cp -r \"$WORK_DIR/vendor/build.prop\" \"$TARGET_FIRMWARE_DEST/vendor\""
EVAL "cp -r \"$MODPATH/tree/system\" \"$TARGET_FIRMWARE_DEST/system\""
SET_PROP_INTO_FILE "$TARGET_FIRMWARE_DEST/system/system/build.prop" "ro.build.flavor" "m51nsxx-user"
SET_PROP_INTO_FILE "$TARGET_FIRMWARE_DEST/system/system/build.prop" "ro.system.build.fingerprint" "samsung/m51nsxx/qssi:12/SP1A.210812.016/M515FXXS6DXE4:user/release-keys"
EVAL "rm -rf \"$MODPATH/tree\""
DOWNLOAD_FILE "https://raw.githubusercontent.com/mehedihjoy0/M51-FIRMWARE/refs/heads/main/vbmeta.img" "$TARGET_FIRMWARE_DEST/avb/vbmeta.img"
LOG_STEP_OUT 

LOG "- M51IFY has been completed successfully"

unset -f SET_PROP_INTO_FILE
unset REMOVAL_LIST TARGET_FIRMWARE_DEST