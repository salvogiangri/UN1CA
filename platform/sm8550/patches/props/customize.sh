# Spoof device name (Some users have reported that their display config looked weird permanently after installing a random magisk module / OneUI 7 Beta)
# This does not seem to cause any other problems
SET_PROP "vendor" "ro.product.vendor.device" "${TARGET_CODENAME}xxx"
