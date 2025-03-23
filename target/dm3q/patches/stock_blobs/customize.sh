SKIPUNZIP=1

echo "Add stock WifiRROverlayAppLargeTcpBuffer overlay"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/app/WifiRROverlayAppLargeTcpBuffer/WifiRROverlayAppLargeTcpBuffer.apk" 0 0 644 "u:object_r:system_file:s0"

echo "Add stock system features"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.spen_usp_level60.xml" 0 0 644 "u:object_r:system_file:s0"
