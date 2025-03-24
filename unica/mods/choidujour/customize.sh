SKIPUNZIP=1

SET_PROP "system" "ro.unica.version" "$ROM_VERSION"
SET_PROP "system" "ro.unica.codename" "$ROM_CODENAME"

if $ROM_IS_OFFICIAL; then
    SET_PROP "system" "ro.unica.timestamp" "$ROM_BUILD_TIMESTAMP"

    ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/choidujour" "system" "." 0 0 755 "u:object_r:system_file:s0"

    CERT_NAME="aosp_testkey"
    [ -f "$SRC_DIR/unica/security/unica_ota.x509.pem" ] && CERT_NAME="unica_ota"

    rm "$WORK_DIR/system/system/etc/security/otacerts.zip"
    cd "$SRC_DIR" ; zip -q "$WORK_DIR/system/system/etc/security/otacerts.zip" "./unica/security/$CERT_NAME.x509.pem" ; cd - &> /dev/null
else
    echo "Build is not official. Ignoring"
fi
