LOG_STEP_IN "- Adding stock WFD blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/bin/insthk" 0 2000 755 "u:object_r:insthk_exec:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhdcp2.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libstagefright_hdcp.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock hwui blobs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhwui.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Camera ISP (Image Signal Processor) blobs"
# SwIsp (Software ISP) libraries - required for camera Super Night mode
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# AIQ (Auto Image Quality) Solution libraries - required for camera AI processing
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libAIQSolution_MPI.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Display Configuration Files"
# Display DPU configs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU660.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU670.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU720.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU7__.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU820.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU8__.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/DPU9__.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/advanced_sf_offsets.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
# Backlight calibration files
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_r66451_amoled_cmd_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_r66451_amoled_video_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_cmd_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_qsync_cmd_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_qsync_video_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/backlight_calib_vtdr6130_amoled_video_mode_dsi_visionox_panel_with_DSC.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
# QDCM calibration data
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_DM2_S6E3FAC_AMB655AY01.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_2k_cmd_mode_qsync_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_2k_video_mode_qsync_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_4k_cmd_mode_dsc_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_4k_video_mode_dsc_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_Sharp_qhd_cmd_mode_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_nt36672e_lcd_video_mode_dsi_novatek_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_nt36672e_lcd_video_mode_dsi_novatek_panel_without_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_cmd_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_cmd_mode_dsi_visionox_panel_without_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_video_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_r66451_amoled_video_mode_dsi_visionox_panel_without_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_sharp_1080p_cmd_mode_dsi_panel.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_cmd_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_qsync_cmd_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_qsync_video_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/display/qdcm_calib_data_vtdr6130_amoled_video_mode_dsi_visionox_panel_with_DSC.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding CDSP blobs"
# CDSP binaries and init files
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "bin/cdsprpcd" 0 2000 755 "u:object_r:cdsprpcd_exec:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "etc/init/vendor.qti.cdsprpc-service.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"

# CDSP libraries (lib)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libcdsp_default_listener.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libcdsprpc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libfastcvdsp_stub.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib/libfastcvopt.so" 0 0 644 "u:object_r:vendor_file:s0"

# CDSP libraries (lib64)
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libcdsp_default_listener.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libcdsprpc.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libfastcvdsp_stub.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "lib64/libfastcvopt.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

