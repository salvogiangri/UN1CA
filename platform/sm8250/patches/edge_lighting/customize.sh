# Fix Edge lighting corner radius
SET_PROP "system" "ro.factory.model" "$(GET_PROP "vendor" "ro.product.vendor.model")"
SET_PROP "system" "ro.product.system.model" "$(GET_PROP "vendor" "ro.product.vendor.model")"
SET_PROP "system" "ro.product.system.name" "$(GET_PROP "vendor" "ro.product.vendor.name")"
