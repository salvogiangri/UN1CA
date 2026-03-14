LOG_STEP_IN "- Adding the latest modified DXE4 firmware for Galaxy M51"
EVAL "git clone \"https://github.com/mehedihjoy0/M51-FIRMWARES\" \"$TMP_DIR/M51-FIRMWARES\""
EVAL "rm -rf \"$TMP_DIR/M51-FIRMWARES/.git\""

FIRMWARES=$(find "$TMP_DIR/M51-FIRMWARES" -type f -print)

for split_firmware in $FIRMWARES; do
 base_firmware="${split_firmware%.??}"
 if [[ "$split_firmware" =~ \.[0-9][0-9]$ ]] && [ -e "$base_firmware.00" ]; then
  if cat "$base_firmware".?? > "$base_firmware" 2>/dev/null; then
    EVAL "rm -f \"$base_firmware\".??"
  fi
 fi
done

EVAL "mv \"$TMP_DIR/M51-FIRMWARES/\"* \"$TMP_DIR\""
EVAL "rm -rf \"$TMP_DIR/M51-FIRMWARES\""
LOG_STEP_OUT

