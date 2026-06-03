# Copyright (c) 2026 Majaahh
# SPDX-License-Identifier: GPL-3.0-or-later

# Firmware
if [ -d "$WORK_DIR/vendor/firmware/SM-A536B" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-A536B\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-A536B\""
SET_METADATA "vendor" "firmware/SM-A536B" 0 2000 755 "u:object_r:vendor_fw_file:s0"

for f in "AP_AUDIO_SLSI.bin" "APDV_AUDIO_SLSI.bin" \
        "calliope_sram.bin" "mfc_fw.bin" "NPU.bin" \
        "os.checked.bin" "vts.bin"; do
    LOG "- Moving /vendor/firmware/$f to /vendor/firmware/SM-A536B/$f"
    EVAL "mv \"$WORK_DIR/vendor/firmware/$f\" \"$WORK_DIR/vendor/firmware/SM-A536B/$f\""
    SET_METADATA "vendor" "firmware/SM-A536B/$f" 0 0 644 "u:object_r:vendor_fw_file:s0"

    LOG "- Creating dummy /vendor/firmware/$f"
    EVAL "touch \"$WORK_DIR/vendor/firmware/$f\""
done

# TEEgris - Firmware
TEEGRIS_ZIPS=(
    # a53xzc (chn_open)
    "A5360ZCSHFYH1_CHC_CHC/A5360ZCSHFYH1_tee.zip"
    # a53xzh (chn_hk)
    "A5360ZHSHFYI1_TGY_OZS/A5360ZHSHFYI1_tee.zip"
    # a53xnsxx (cis_open)
    "A536EXXSHFYI4_INS_ODM/A536EXXSHFYI4_tee.zip"
    # a53xksx (kor_singlex)
    "A536NKSSCFYH1_KOO_OKR/A536NKSSCFYH1_tee.zip"
    # a53xkdi (jpn_kdi)
    "SCG15KDU1DYF1_KDI_QDI/SCG15KDU1DYF1_tee.zip"
    # a53xdcm (jpn_dcm)
    "SC53COMU1DYF2_DCM_DCM/SC53COMU1DYF2_tee.zip"
)

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\""
fi
EVAL "mkdir -p \"$TMP_DIR\""

if [ -d "$WORK_DIR/vendor/firmware/tee" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/tee\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/tee\""
SET_METADATA "vendor" "firmware/tee" 0 2000 755 "u:object_r:tee_file:s0"

for f in "${TEEGRIS_ZIPS[@]}"; do
    FILE_NAME="$(basename "$f")"

    LOG "- Downloading $FILE_NAME"
    DOWNLOAD_FILE "https://github.com/UN1CA/proprietary_vendor_samsung_a53x/releases/download/$f" "$TMP_DIR/$FILE_NAME"

    MODEL="$(cut -c1-5 <<< "$FILE_NAME")"
    if [[ "$MODEL" != "SCG15" ]]; then
        MODEL="${MODEL//SC/SC-}"
        if [[ "$MODEL" != "SC-53C" ]]; then
            MODEL="SM-$MODEL"    
        fi
    fi

    TEE_DIR="$WORK_DIR/vendor/firmware/tee/$(cut -c1-13 <<< "$FILE_NAME")"

    if [ -d "$TEE_DIR" ]; then
        EVAL "rm -rf \"$TEE_DIR\""
    fi
    EVAL "mkdir -p \"$TEE_DIR\""
    SET_METADATA "vendor" "firmware/tee/$(basename "$TEE_DIR")" 0 2000 755 "u:object_r:tee_file:s0"

    LOG "- Extracting ${TMP_DIR//$SRC_DIR\//}/$FILE_NAME to /${TEE_DIR//$WORK_DIR\//}"
    EVAL "unzip \"$TMP_DIR/$FILE_NAME\" -d \"$TEE_DIR\""

    LOG "- Adding SEPolicy for TAs in /${TEE_DIR//$WORK_DIR\//}"
    while IFS= read -r t; do
        GROUP=0
        MODE="644"
        if [ -d "$TEE_DIR/$t" ]; then
            GROUP="2000"
            MODE="755"
        fi

        SET_METADATA "vendor" "firmware/tee/$(basename "$TEE_DIR")/$t" 0 "$GROUP" "$MODE" "u:object_r:tee_file:s0" > /dev/null

        unset GROUP MODE
    done < <(find "$TEE_DIR" | sed "s|$TEE_DIR||g" | sed "s/^\///g" | sed "/^\$/d")

    EVAL "rm -f \"$TMP_DIR/$FILE_NAME\""

    unset FILE_NAME MODEL TEE_DIR
done

# NXP NFC Support
LOG_STEP_IN "- Deleting SLSI NFC init"
DELETE_FROM_WORK_DIR "vendor" "etc/init/sec.android.hardware.nfc@1.2-service.rc"
LOG_STEP_OUT

LOG_STEP_IN "- Adding NXP NFC blobs"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "bin/hw/nxp.android.hardware.nfc@1.2-service"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "etc/libnfc-nxp.conf"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "etc/nfc/libnfc-nxp_RF.conf"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "firmware/nfc/libsn100u_fw.so"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "lib64/nfc_nci_nxpsn.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding NXP eSE blobs"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "etc/libese-nxp.conf"
ADD_TO_WORK_DIR "a53xtfn" "vendor" "lib64/ese_spi_nxp.so"
LOG_STEP_OUT

LOG_STEP_IN "- Setting up libnfc-nci configuration"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci.conf" 0 0 644 "u:object_r:system_file:s0"
LOG "- Renaming /system/system/etc/libnfc-nci.conf to /system/system/etc/libnfc-nci-SLSI.conf"
EVAL "mv \"$WORK_DIR/system/system/etc/libnfc-nci.conf\" \"$WORK_DIR/system/system/etc/libnfc-nci-SLSI.conf\""
SET_METADATA "system" "system/etc/libnfc-nci-SLSI.conf" 0 0 644 "u:object_r:system_file:s0"

ADD_TO_WORK_DIR "a53xtfn" "system" "system/etc/libnfc-nci.conf"
LOG "- Renaming /system/system/etc/libnfc-nci.conf to /system/system/etc/libnfc-nci-NXP.conf"
EVAL "mv \"$WORK_DIR/system/system/etc/libnfc-nci.conf\" \"$WORK_DIR/system/system/etc/libnfc-nci-NXP.conf\""
SET_METADATA "system" "system/etc/libnfc-nci-NXP.conf" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

# Properties
ADD_TO_WORK_DIR "$MODPATH" "vendor_dlkm" "." 0 0 755 "u:object_r:vendor_file:s0"

for i in "odm" "vendor" "vendor_dlkm"; do
    PROP="$i/etc/build.prop"
    if [[ "$i" == "vendor" ]]; then
        PROP="$i/build.prop"
    fi

    {
        echo "# Added by target/a53x/patches/variants/customize.sh"
        echo "import /$i/etc/sku/\${ro.boot.em.model}.prop"
    } >> "$WORK_DIR/$PROP"

    unset PROP
done

LOG "- Adding SELinux entries"
{
    echo "(allow init_31_0 tee_file (dir (mounton)))"
    echo "(allow priv_app_31_0 tee_file (dir (getattr)))"
    echo "(allow init_31_0 vendor_fw_file (file (mounton)))"
    echo "(allow priv_app_31_0 vendor_fw_file (file (getattr)))"
    echo "(allow init_31_0 vendor_npu_firmware_file (file (mounton)))"
    echo "(allow priv_app_31_0 vendor_npu_firmware_file (file (getattr)))"
} >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil" || return 1

# Nuke model checks
# Before: [mov r7,r0]
# After: [movs r7,#0x1]
HEX_PATCH "$WORK_DIR/vendor/lib/soundfx/libswdap.so" "3046884707463068" "3046884701273068"

# Before: [
#  ldr x8,[x8, #0x10]
#  blr x8
# ]
# After: [
#  mov w0,#0x1
#  nop
# ]
HEX_PATCH "$WORK_DIR/vendor/lib64/soundfx/libswdap.so" "e00315aa080940f900013fd6" "e00315aa200080521f2003d5"

unset TEEGRIS_ZIPS
