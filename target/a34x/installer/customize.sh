A346B_FIRMWARE_URL="https://github.com/UN1CA/proprietary_vendor_samsung_a34x/releases/download/EYI7-firmware/A346BXXUBEYI7_mtk_fw.tar.md5"
A346E_FIRMWARE_URL="https://github.com/UN1CA/proprietary_vendor_samsung_a34x/releases/download/EYI7-firmware/A346EXXUAEYI7_mtk_fw.tar.md5"
A346M_FIRMWARE_URL="https://github.com/UN1CA/proprietary_vendor_samsung_a34x/releases/download/EYI7-firmware/A346MUBUBEYI7_mtk_fw.tar.md5"

A346B_VBMETA_URL="https://github.com/UN1CA/proprietary_vendor_samsung_a34x/releases/download/patched-vbmeta/A346BXXUBEYI7_patched_vbmeta.tar.md5"
A346E_VBMETA_URL="https://github.com/UN1CA/proprietary_vendor_samsung_a34x/releases/download/patched-vbmeta/A346EXXUAEYI7_patched_vbmeta.tar.md5"
A346M_VBMETA_URL="https://github.com/UN1CA/proprietary_vendor_samsung_a34x/releases/download/patched-vbmeta/A346MUBUBEYI7_patched_vbmeta.tar.md5"

if [ -d "$TMP_DIR/firmware" ]; then
   EVAL "rm -rf \"$TMP_DIR/firmware\""
fi
EVAL "mkdir -p \"$TMP_DIR/firmware\""

for f in A346B A346E A346M; do
    LOG "- Downloading firmware package for $f"

    var="${f}_FIRMWARE_URL"
    FIRMWARE_URL="${!var}"

    if [ -d "$TMP_DIR/firmware/tmp" ]; then
        EVAL "rm -rf \"$TMP_DIR/firmware/tmp\""
    fi
    EVAL "mkdir -p \"$TMP_DIR/firmware/tmp\""

    DOWNLOAD_FILE "$FIRMWARE_URL" "$TMP_DIR/firmware/tmp/firmware.tar"

    EXPECTED_HASH="$(tail -z -n 1 "$TMP_DIR/firmware/tmp/firmware.tar" | cut -d' ' -f 1)"
    HASH="$(cat "$TMP_DIR/firmware/tmp/firmware.tar" | xxd -p -c 0 | sed "s/$(tail -z -n 1 "$TMP_DIR/firmware/tmp/firmware.tar" | xxd -p -c 0)//" | xxd -p -r -c 0 | md5sum | cut -d' ' -f 1)"

    [[ "$HASH" == "$EXPECTED_HASH" ]] || ABORT "- Downloaded firmware .tar.md5 file hash missing or mismatches. Aborting"

    LOG "- Downloading vbmeta package for $f"

    var="${f}_VBMETA_URL"
    VBMETA_URL="${!var}"

    DOWNLOAD_FILE "$VBMETA_URL" "$TMP_DIR/firmware/tmp/vbmeta.tar"

    EXPECTED_HASH="$(tail -z -n 1 "$TMP_DIR/firmware/tmp/vbmeta.tar" | cut -d' ' -f 1)"
    HASH="$(cat "$TMP_DIR/firmware/tmp/vbmeta.tar" | xxd -p -c 0 | sed "s/$(tail -z -n 1 "$TMP_DIR/firmware/tmp/vbmeta.tar" | xxd -p -c 0)//" | xxd -p -r -c 0 | md5sum | cut -d' ' -f 1)"

    [[ "$HASH" == "$EXPECTED_HASH" ]] || ABORT "- Downloaded vbmeta .tar.md5 file hash missing or mismatches. Aborting"

    EVAL "tar xf \"$TMP_DIR/firmware/tmp/firmware.tar\" -C \"$TMP_DIR/firmware/tmp\""
    EVAL "tar xf \"$TMP_DIR/firmware/tmp/vbmeta.tar\" -C \"$TMP_DIR/firmware/tmp\""

    PARTITIONS="
    audio_dsp-verified.img
    cam_vpu1-verified.img
    cam_vpu2-verified.img
    cam_vpu3-verified.img
    dtbo.img
    scp-verified.img
    vbmeta.img
    "

    EVAL "mkdir \"$TMP_DIR/firmware/$f\""
    for i in $PARTITIONS; do
        [[ ! -f "$TMP_DIR/firmware/tmp/$i.lz4" ]] && ABORT "- Missing $i in $f firmware or vbmeta package"
        EVAL "unlz4 -f \"$TMP_DIR/firmware/tmp/$i.lz4\" \"$TMP_DIR/firmware/$f/$i\""
    done

    EVAL "rm -rf \"$TMP_DIR/firmware/tmp\""

    unset FIRMWARE_URL var HASH EXPECTED_HASH VBMETA_URL
done

# Nuke unsigned DTBO flashing
sed -i '/ui_print("Full Patching dtbo\.img img\.\.\.");/d' "$TMP_DIR/META-INF/com/google/android/updater-script"
sed -i '/package_extract_file("dtbo\.img", "\/dev\/block\/by-name\/dtbo");/d' "$TMP_DIR/META-INF/com/google/android/updater-script"
EVAL "rm \"$TMP_DIR/dtbo.img\""
