#
# Copyright (C) 2025 Fede2782
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# MediaTek Compatibility Module

if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" != "mssi" ]]; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    return 0
fi

# [
# ADD_JAR_TO_CLASSPATH "<file>" "<classpath scope>" "<jar path>" "<min api>" "<max api>"
# Adds the given jar to the classpath and with the given scope and, optionally, sdk versions.
# If you specify max api you CANNOT omit min api but you can leave it blank/empty.
# Scope can be any value from: UNKNOWN, BOOTCLASSPATH, SYSTEMSERVERCLASSPATH, DEX2OATBOOTCLASSPATH, STANDALONE_SYSTEMSERVER_JARS
ADD_JAR_TO_CLASSPATH()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1"
    _CHECK_NON_EMPTY_PARAM "SCOPE" "$2"
    _CHECK_NON_EMPTY_PARAM "JAR_PATH" "$3"

    local FILE="$1"
    local SCOPE="$2"
    local JAR_PATH="$3"
    local MIN_API="$4"
    local MAX_API="$5"
    local PROTO="$MODPATH/classpaths.proto"
    local CMD

    if [[ "$FILE" == "bootclasspath" ]]; then
        FILE="$WORK_DIR/system/system/etc/classpaths/bootclasspath.pb"
    elif [[ "$FILE" == "systemserverclasspath" ]]; then
        FILE="$WORK_DIR/system/system/etc/classpaths/systemserverclasspath.pb"
    fi

    if [ ! -f "$FILE" ]; then
        LOGE "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    if [[ "$SCOPE" != "UNKNOWN" ]] && [[ "$SCOPE" != "BOOTCLASSPATH" ]] && [[ "$SCOPE" != "SYSTEMSERVERCLASSPATH" ]] && \
            [[ "$SCOPE" != "DEX2OATBOOTCLASSPATH" ]] && [[ "$SCOPE" != "STANDALONE_SYSTEMSERVER_JARS" ]]; then
        LOGE "\"$SCOPE\" is not a valid scope"
        return 1
    fi

    # Decode given binary file to text
    EVAL "cd \"$(dirname "$FILE")\"; protoc --decode=ExportedClasspathsJars --proto_path=\"$(dirname "$PROTO")\" \"$(basename "$PROTO")\" < \"$(basename "$FILE")\" > \"$(basename "$FILE").txt\""

    # Add to the text file
    {
        echo "jars {"
        echo "  path: \"$JAR_PATH\""
        echo "  classpath: $SCOPE"
        if [ "$MIN_API" ]; then
            echo "  min_sdk_version: \"$MIN_API\""
        fi
        if [ "$MAX_API" ]; then
        echo "  max_sdk_version: \"$MAX_API\""
        fi
        echo "}"
    } >> "$(dirname "$FILE")/$(basename "$FILE").txt"

    # Encode back text file to binary
    CMD="cd \"$(dirname "$FILE")\"; protoc --encode=ExportedClasspathsJars --proto_path=\"$(dirname "$PROTO")\" \"$(basename "$PROTO")\" < \"$(basename "$FILE").txt\" > \"$(basename "$FILE")\""
    EVAL "$CMD"
    EVAL "rm \"$(dirname "$FILE")/$(basename "$FILE").txt\""
}
# ]

if [[ "$SOURCE_EXTRA_FIRMWARES" != "SM-A346"* ]]; then
    LOGE "- Unsupported firmware for MediaTek Compatibility Module"
    exit 1
fi

# UN1CA: this patch is not complete! It relies on the whole build system and modules to produce a working
# MediaTek-compatible image.

IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
MODEL=$(cut -d "/" -f 1 -s <<< "${SOURCE_EXTRA_FIRMWARES[0]}")
REGION=$(cut -d "/" -f 2 -s <<< "${SOURCE_EXTRA_FIRMWARES[0]}")

LOG_STEP_IN "- Patching system_ext"
# bin, lib64, lib
DELETE_FROM_WORK_DIR "system_ext" "bin"
DELETE_FROM_WORK_DIR "system_ext" "lib64"
DELETE_FROM_WORK_DIR "system_ext" "lib"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "bin"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "lib64"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "lib"

# usp
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "usp"

# frameworks
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/mediatek-common.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/mediatek-ims-base.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/mediatek-framework.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/CustomPropInterface.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/DataChannelApi.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/duraspeed.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "framework/log-handler.jar"

ADD_JAR_TO_CLASSPATH "bootclasspath" "BOOTCLASSPATH" "/system_ext/framework/mediatek-common.jar"
ADD_JAR_TO_CLASSPATH "bootclasspath" "DEX2OATBOOTCLASSPATH" "/system_ext/framework/mediatek-common.jar"
ADD_JAR_TO_CLASSPATH "bootclasspath" "BOOTCLASSPATH" "/system_ext/framework/mediatek-framework.jar"
ADD_JAR_TO_CLASSPATH "bootclasspath" "DEX2OATBOOTCLASSPATH" "/system_ext/framework/mediatek-framework.jar"
ADD_JAR_TO_CLASSPATH "bootclasspath" "BOOTCLASSPATH" "/system_ext/framework/mediatek-ims-base.jar"
ADD_JAR_TO_CLASSPATH "bootclasspath" "DEX2OATBOOTCLASSPATH" "/system_ext/framework/mediatek-ims-base.jar"

# etc
DELETE_FROM_WORK_DIR "system_ext" "etc/init"
DELETE_FROM_WORK_DIR "system_ext" "etc/selinux"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "etc/selinux"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "etc/init"

FTP="
a2dp_audio_policy_configuration.xml
a2dp_in_audio_policy_configuration.xml
aee-commit
aee-config
audio_policy_configuration_bluetooth_legacy_hal.xml
audio_policy_configuration_stub.xml
audio_policy_configuration.xml
audio_policy_engine_configuration.xml
audio_policy_engine_default_stream_volumes.xml
audio_policy_engine_product_strategies.xml
audio_policy_engine_stream_volumes.xml
audio_policy_volumes.xml
bluetooth_audio_policy_configuration.xml
custom.conf
default_volume_tables.xml
hearing_aid_audio_policy_configuration.xml
mtklog-config.prop
nr-city.xml
r_submix_audio_policy_configuration.xml
spn-conf.xml
usb_audio_policy_configuration.xml
"

for f in $FTP; do
    ADD_TO_WORK_DIR "$MODEL/$REGION" "system_ext" "etc/$f"
done

LOG_STEP_OUT

LOG_STEP_IN "- Patching system"
# etc
DELETE_FROM_WORK_DIR "system" "system/etc/init"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/init"

DELETE_FROM_WORK_DIR "system" "system/etc/vintf"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/vintf"

ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/public.libraries-mtk.txt"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/public.libraries-trustonic.txt"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/public.libraries-camera.samsung.txt"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/public.libraries-arcsoft.txt"

ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/permissions/verizon_net_sip_library.xml"

FTP="
resolution_tuner_app_list.xml
open_msync_app_list.xml
msync_ctrl_table.xml
audio_effects.conf
ams_aal_config.xml
TelephonyLog_dynamic.ds
"

for f in $FTP; do
    ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/etc/$f"
done

# bin, lib64, lib
DELETE_FROM_WORK_DIR "system" "system/bin"
DELETE_FROM_WORK_DIR "system" "system/lib64"
DELETE_FROM_WORK_DIR "system" "system/lib"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/bin"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/lib64"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/lib"

VEX_LIBS="
system/lib64/libandroid.vexfwk.samsung.so
system/lib64/libcommon-jni.vexfwk.samsung.so
system/lib64/libimgproc.vexfwk.samsung.so
system/lib64/libmetadata.vexfwk.samsung.so
system/lib64/libndk.vexfwk.samsung.so
system/lib64/libruntime.vexfwk.samsung.so
system/lib64/libsdk-v2-jni.vexfwk.samsung.so
system/lib64/vexfwk_service_aidl-ndk.so
system/lib/libandroid.vexfwk.samsung.so
system/lib/libcommon-jni.vexfwk.samsung.so
system/lib/libimgproc.vexfwk.samsung.so
system/lib/libmetadata.vexfwk.samsung.so
system/lib/libndk.vexfwk.samsung.so
system/lib/libruntime.vexfwk.samsung.so
system/lib/libsdk-v2-jni.vexfwk.samsung.so
system/lib/vexfwk_service_aidl-ndk.so
"
for lib in $VEX_LIBS; do
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "$lib"
done

ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/lib64/libsec_camerax_util_jni.camera.samsung.so"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/lib/libsec_camerax_util_jni.camera.samsung.so"
{
    echo "libsec_camerax_util_jni.camera.samsung.so"
} >> "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"

DELETE_FROM_WORK_DIR "system" "system/lib64/libtensorflowLite.myfilter.camera.samsung.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libtensorflowlite_inference_api.myfilter.camera.samsung.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libdualcam_portraitlighting_gallery_360_lite.so"

LIBS="
system/lib64/libStride.camera.samsung.so
system/lib64/libStrideTensorflowLite.camera.samsung.so
system/lib64/extractors/libsapeextractor.so
system/lib64/extractors/libsdffextractor.so
system/lib64/extractors/libsdsfextractor.so
system/lib64/libscalenetpkg.so
system/lib64/libSceneDetector_v1.camera.samsung.so
system/lib64/libimage_enhancement.arcsoft.so
system/lib64/libdualcam_portraitlighting_gallery_360.so
system/lib64/libtensorflowLite.camera.samsung.so
system/lib64/libMyFilter.camera.samsung.so
system/lib64/libtensorflowlite_inference_api.camera.samsung.so
system/lib64/libtensorflowLite2_11_0_dynamic_camera.so
system/lib64/libLttEngine.camera.samsung.so
system/lib64/libAuraRenderer.graphics.samsung.so
system/lib64/libDocShadowRemoval.arcsoft.so
system/lib64/libDeepDocRectify.camera.samsung.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/libstartrail.camera.samsung.so
system/lib64/libdvs.camera.samsung.so
system/lib64/libPetClustering.camera.samsung.so
system/lib64/lib_pet_detection.arcsoft.so
system/lib64/libRelighting_API.camera.samsung.so
system/lib64/libBestPhoto.camera.samsung.so
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libAEBHDR_wrapper.camera.samsung.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libarcsoft_single_cam_glasses_seg.so
system/lib64/libarcsoft_superresolution_bokeh.so
system/lib64/libdualcam_refocus_image.so
system/lib64/libhigh_dynamic_range_bokeh.so
system/lib64/libhighres_enhancement.arcsoft.so
system/lib64/libHREnhancementAPI.camera.samsung.so
system/lib64/libFaceRecognition.arcsoft.so
system/lib64/libfrtracking_engine.arcsoft.so
system/lib64/libMPISingleRGB40.camera.samsung.so
system/lib64/libMPISingleRGB40Tuning.camera.samsung.so
system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so
system/lib64/libAIQSolution_MPI.camera.samsung.so
system/lib64/libLocalTM_pcc.camera.samsung.so
system/lib64/libObjectDetector_v1.camera.samsung.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
"
for lib in $LIBS; do
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "$lib"
done

LIBS="
system/lib64/libVideoClassifier.camera.samsung.so
system/lib64/libhybridHDR_wrapper.camera.samsung.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
"
for lib in $LIBS; do
    ADD_TO_WORK_DIR "gts11xx" "system" "$lib"
done

{
    echo "libtensorflowLite.camera.samsung.so"
    echo "libtensorflowlite_inference_api.camera.samsung.so"
    echo "libLttEngine.camera.samsung.so"
    echo "libBestPhoto.camera.samsung.so"
    echo "libVideoClassifier.camera.samsung.so"
    echo "libstartrail.camera.samsung.so"
    echo "libObjectDetector_v1.camera.samsung.so"
    echo "libPetClustering.camera.samsung.so"
    echo "libImageSegmenter_v1.camera.samsung.so"
    echo "libSceneDetector_v1.camera.samsung.so"
    echo "libAEBHDR_wrapper.camera.samsung.so"
    echo "libDualCamBokehCapture.camera.samsung.so"
    echo "libHREnhancementAPI.camera.samsung.so"
    echo "libhybridHDR_wrapper.camera.samsung.so"
    echo "libAIQSolution_MPISingleRGB40.camera.samsung.so"
    echo "libMPISingleRGB40.camera.samsung.so"
    echo "libAIQSolution_MPI.camera.samsung.so"
    echo "libSwIsp_wrapper_v1.camera.samsung.so"
    echo "libMultiFrameProcessing30.camera.samsung.so"
    echo "libLocalTM_pcc.camera.samsung.so"
    echo "libsuperresolutionraw_wrapper_v2.camera.samsung.so"
    echo "libdvs.camera.samsung.so"
    echo "libsaiv_HprFace_cmh_support_jni.camera.samsung.so"
    echo "libHpr_RecFace_dl_v1.0.camera.samsung.so"
    echo "libFace_Landmark_Engine.camera.samsung.so"
} >> "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"

{
    echo "lib_pet_detection.arcsoft.so"
    echo "libae_bracket_hdr.arcsoft.so"
    echo "libhybrid_high_dynamic_range.arcsoft.so"
    echo "libimage_enhancement.arcsoft.so"
    echo "libfrtracking_engine.arcsoft.so"
    echo "libFaceRecognition.arcsoft.so"
    echo "libsuperresolution_raw.arcsoft.so"
} >> "$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt"

# Frameworks
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/framework/verizon.net.sip.jar"
ADD_TO_WORK_DIR "$MODEL/$REGION" "system" "system/framework/msync-lib.jar"

# Remove unsupported features
DELETE_FROM_WORK_DIR "system" "system/etc/public.libraries-edensdk.samsung.txt"

# Disable live blur and Relumino
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_GRAPHICS_SUPPORT_3D_SURFACE_TRANSITION_FLAG" --delete
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_GRAPHICS_SUPPORT_RELUMINO_EFFECT_FLAG" --delete

# Bluetooth
ADD_TO_WORK_DIR "gts11xx" "system" "system/apex/com.android.bt.apex"

LOG_STEP_OUT

LOG_STEP_IN "- Adding system properties"

# Fix MediaExtractor
SET_PROP "system" "media.extractor.sec.dolby-lib-version" "$(GET_PROP "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop" "media.extractor.sec.dolby-lib-version")"
SET_PROP "system" "media.extractor.sec.pcm-32bit" --delete

# MediaTek SSI info
SET_PROP "system" "ro.mediatek.version.branch" "$(GET_PROP "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop" "ro.mediatek.version.branch")"
SET_PROP "system" "ro.mediatek.version.release" "$(GET_PROP "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop" "ro.mediatek.version.release")"
SET_PROP "system" "Build.BRAND" "MTK"
SET_PROP "system" "ro.base_build" "noah"

# MediaTek audio
SET_PROP "system_ext" "ro.audio.ihaladaptervendorextension_enabled" "true"
SET_PROP "system" "ro.audio.ihaladaptervendorextension_enabled" "true"
SET_PROP "system" "ro.audio.usb.period_us" "16000"
SET_PROP "system" "vendor.af.threshold.src_and_effect_count" "5"
SET_PROP "system" "vendor.af.pausewait.enable" "false"
SET_PROP "system" "vendor.af.dynamic.sleeptime.enable" "true"
SET_PROP "system" "ro.audio.flinger_standbytime_ms" "1000"
SET_PROP "system" "persist.audio.deepbuffer_delay" "0"
SET_PROP "system" "ro.camera.sound.forced" "0"
SET_PROP "system" "ro.audio.silent" "0"

# MediaTek surfaceflinger
SET_PROP "system" "debug.sf.enable_gl_backpressure" "0"
SET_PROP "system" "debug.sf.treat_170m_as_sRGB" "1"
SET_PROP "system" "debug.sf.predict_hwc_composition_strategy" "0"
SET_PROP "system" "debug.sf.enable_transaction_tracing" "false"

# MediaTek AEE (Android Exception Enhancement)
SET_PROP "system" "ro.vendor.have_aee_feature" "1"

# MediaTek Connectivity (WLAN/RIL)
SET_PROP "system" "vendor.rild.libpath" "mtk-ril.so"
SET_PROP "system" "vendor.rild.libargs" "-d /dev/ttyC0"
SET_PROP "system" "wifi.interface" "wlan0"
SET_PROP "system" "ro.mediatek.wlan.wsc" "1"
SET_PROP "system" "ro.mediatek.wlan.p2p" "1"
SET_PROP "system" "mediatek.wlan.ctia" "0"
SET_PROP "system" "persist.mtk_telecom_max_ringingcall_number" "1"
SET_PROP "system" "persist.vendor.pco5.radio.ctrl" "0"
SET_PROP "system" "wifi.direct.interface" "p2p0"
SET_PROP "system" "ro.vendor.mtk_telephony_add_on_policy" "0"
SET_PROP "system" "persist.vendor.wfc.sys_wfc_support" "1"
SET_PROP "system" "ro.vendor.customer_logpath" "/data"
SET_PROP "system" "wifi.tethering.interface" "ap0"
SET_PROP "system" "persist.vendor.vzw_device_type" "0"
SET_PROP "system" "ro.vendor.mtk_omacp_support" "1"
SET_PROP "system" "persist.vendor.mtk.vilte.enable" "1"
SET_PROP "system" "persist.vendor.vilte_support" "1"
SET_PROP "system" "persist.vendor.pms_removable" "1"

# MediaTek Media
SET_PROP "system" "media.stagefright.thumbnail.prefer_hw_codecs" "true"
SET_PROP "system" "vendor.mtk_thumbnail_optimization" "true"
SET_PROP "system" "ro.vendor.mtk_flv_playback_support" "1"
SET_PROP "system" "debug.stagefright.c2inputsurface" "-1"

# MediaTek performance framework
SET_PROP "system" "ro.mtk_perf_simple_start_win" "1"
SET_PROP "system" "ro.mtk_perf_fast_start_win" "1"
SET_PROP "system" "ro.mtk_perf_response_time" "1"

# USB
SET_PROP "system" "ro.sys.usb.mtp.whql.enable" "0"
SET_PROP "system" "ro.sys.usb.storage.type" "mtp"
SET_PROP "system" "ro.sys.usb.bicr" "no"
SET_PROP "system" "ro.sys.usb.charging.only" "yes"

# Miscs
SET_PROP "system" "persist.sys.fuse.passthrough.enable" "true"
SET_PROP "system" "ro.iorapd.enable" "false"
SET_PROP "system" "ro.property_service.async_persist_writes" "true"
SET_PROP "system" "persist.vendor.mdlog.flush_log_ratio" "0"
SET_PROP "system" "ro.opengles.version" "196610"
SET_PROP "system" "ro.zygote.preload.enable" "0"
SET_PROP "system" "qemu.hw.mainkeys" "0"
SET_PROP "system" "ro.kernel.zio" "38,108,105,16"

# IPO
SET_PROP "system" "sys.ipo.pwrdncap" "2"
SET_PROP "system" "sys.ipo.disable" "1"

LOG_STEP_OUT

APPLY_PATCH "system" "system/framework/framework.jar" "$MODPATH/pictureQuality/framework.jar/0001-Implement-MTK-PictureQuality.patch"
APPLY_PATCH "system" "system/framework/services.jar" "$MODPATH/pictureQuality/services.jar/0001-Implement-MTK-PictureQuality.patch"

unset MODEL REGION FTP VEX_LIBS LIBS
unset -f ADD_JAR_TO_CLASSPATH
