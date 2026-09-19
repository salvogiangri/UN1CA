# SEC_PRODUCT_FEATURE_COMMON_CONFIG_DEVICE_MANUFACTURING_TYPE
if [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_DEVICE_MANUFACTURING_TYPE")" == "jdm" ]]; then
    ADD_TO_WORK_DIR "gta9pxxx" "system" "system/priv-app/GameOptimizingService/GameOptimizingService.apk" 0 0 644 "u:object_r:system_file:s0"
else
    LOG "\033[0;33m! Nothing to do\033[0m"
    return 0
fi
