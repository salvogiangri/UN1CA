GET_PROP_FROM_FILE()
{
 [ -f "$2" ] || { echo "File not found: $2" >&2; exit 1; }; awk -F= -v p="$1" '$1==p{print substr($0,index($0,"=")+1)}' "$2"; 
}

SET_PROP_INTO_FILE()
{ 
 prop="$1"; val="$2"; file="$3"
 [ -f "$file" ] || { echo "File not found: $file" >&2; return 1; }
 if [ "$val" = "-d" ] || [ "$val" = "--delete" ]; then
   prop="${prop//=*/}"; grep -q "^$prop=" "$file" && { LOG "- Deleting \"$prop\" prop in $file"; sed -i "/^$prop=/d" "$file"; }
 else
   if grep -q "^$prop=" "$file"; then
     LOG "- Replacing \"$prop\" prop with \"$val\" in $file"
     sed -i "s|^$prop=.*|$prop=$val|" "$file"
   else
     LOG "- Adding \"$prop\" prop with \"$val\" in $file"
     grep -q "Added by scripts" "$file" || echo "# Added by scripts/internal/apply_modules.sh" >>"$file"
     echo "$prop=$val" >>"$file"
   fi
 fi
}

LOG "- Patching a52q vendor with m51 device tree"

LOG_STEP_IN "- Removing a52q specific vendor blobs"

LOG_STEP_IN "- Removing init, soundbooster"
DELETE_FROM_WORK_DIR "vendor" "etc/init/hw/init.a52q.rc"
DELETE_FROM_WORK_DIR "vendor" "lib/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "vendor" "lib/hw/audio.primary.atoll.so"
LOG_STEP_OUT

LOG_STEP_IN "- Removing sensor blobs"
DEBLOAT_LIST="$(cd "$WORK_DIR/vendor/etc" 2>/dev/null && find sensors -type f -print 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/M515F/vendor/etc/$file" ] && DELETE_FROM_WORK_DIR "vendor" "etc/$file"
done <<< "$DEBLOAT_LIST"
LOG_STEP_OUT

LOG_STEP_IN "- Removing camera libraries"
DEBLOAT_LIST="$(find "$WORK_DIR/vendor" -type f -path '*/lib*/camera/*' -printf '%P\n' 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    [ ! -f "$MODPATH/M515F/vendor/$file" ] && DELETE_FROM_WORK_DIR "vendor" "$file"
done <<< "$DEBLOAT_LIST"
LOG_STEP_OUT

LOG_STEP_OUT 

LOG_STEP_IN "- Patching a52q properties with m51"
SOURCE_FIRMWARE_PATH="$(cut -d/ -f1 -s <<<"$SOURCE_FIRMWARE")_$(cut -d/ -f2 -s <<<"$SOURCE_FIRMWARE")"
SET_PROP_INTO_FILE "VE" "$(GET_PROP_FROM_FILE "VE" "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/etc/selinux/vendor_sepolicy_version")" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
SET_PROP_INTO_FILE "BD" "$(GET_PROP_FROM_FILE "BD" "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/etc/selinux/vendor_sepolicy_version")" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version"
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
LOG_STEP_OUT

LOG_STEP_IN "- Running hex patches for atoll -> sm6150"
find "$WORK_DIR/vendor" -type f -name '*atoll*' -print0 2>/dev/null |
 while IFS= read -r -d '' f; do
   HEX_PATCH "$f" 61746f6c6c2e736f00 736d363135302e736f
   mv -- "$f" "$(printf '%s' "$f" | sed 's/atoll/sm6150/g')" 2>/dev/null
 done
LOG_STEP_OUT

LOG_STEP_IN "- Replacing a52q props with m51"
sed -i -e 's|siop_a52q_sm7125|siop_m51_sm7150|g' -e 's|a52q|m51|g' -e 's|A52|M51|g' "$WORK_DIR/vendor/etc/floating_feature.xml"
sed -i 's|a52q|m51|g' "$WORK_DIR/vendor/etc/ev_lux_map_config.xml" "$WORK_DIR/vendor/etc/sensorhub_services.json"
sed -i 's|atoll|sm6150|g' "$WORK_DIR/vendor/etc/vramdiskd.xml" "$WORK_DIR/configs/file_context-vendor" "$WORK_DIR/configs/fs_config-vendor"
LOG_STEP_OUT

LOG_STEP_IN "- Adding odm props from source firmware and media profiles from vendor"
cp -a "$WORK_DIR/vendor/etc/media_profiles_V1_0.xml" "$WORK_DIR/odm/etc"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "odm" "etc/build.prop"
LOG_STEP_OUT

LOG "- m51ify has been completed successfully"