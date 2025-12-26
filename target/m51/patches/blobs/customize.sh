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

LOG_STEP_IN "- Performing additional steps before applying the next patches"
TARGET_FIRMWARE_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
cp -r "$MODPATH/system" "$TARGET_FIRMWARE_DEST/system"
SET_PROP_INTO_FILE "$TARGET_FIRMWARE_DEST/system/system/build.prop" "ro.build.flavor" "m51nsxx-user"
SET_PROP_INTO_FILE "$TARGET_FIRMWARE_DEST/system/system/build.prop" "ro.system.build.fingerprint" "samsung/m51nsxx/qssi:12/SP1A.210812.016/M515FXXS6DXE4:user/release-keys"
SET_PROP "product" "ro.product.product.name" "m51nsxx"
LOG_STEP_OUT 

unset -f SET_PROP_INTO_FILE
unset TARGET_FIRMWARE_DEST