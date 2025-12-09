LOG "- Setting key code 703 to VOICE_ASSIST"
sed -i "s/WINK/VOICE_ASSIST/g" "$WORK_DIR/system/system/usr/keylayout/Generic_internal.kl"
