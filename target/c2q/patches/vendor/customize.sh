LOG_STEP_IN "- Updating UWB HAL"

DELETE_FROM_WORK_DIR "vendor" "etc/init/nxp-uwb-service.rc"

BLOBS_LIST="
bin/hw/vendor.samsung.hardware.uwb@1.0-service
etc/libuwb-countrycode.conf
etc/libuwb-feature.conf
etc/libuwb-nxp.conf
etc/libuwb-uci.conf
etc/init/init.vendor.uwb.rc
etc/init/vendor.samsung.hardware.uwb@1.0-service.rc
firmware/uwb
lib64/uwb_uci.hal.so
lib64/libmemunreachable.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3qxxx" "vendor" "$blob"
done

SET_PROP "vendor" "ro.vendor.uwb.feature.chipname" "sr100"
LOG_STEP_OUT
