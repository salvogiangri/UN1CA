# UN1CA SELinux entries debloat list
# - Append new type entries to the ENTRIES list
# - Add the EXACT type entry, DO NOT just add a common pattern (eg. "fabriccrypto", "fabriccrypto_exec" and NOT just "fabriccrypto")
# - DO NOT add the API version at the end of the entry (eg. "fabriccrypto" and NOT "fabriccrypto_30_0")
# - DO NOT add add any parenthesis or statements (eg. "fabriccrypto" and NOT "expanttypeattribute ... (fabriccrypto)")
# - DO NOT add unnecessary types or remove the existing ones unless they aren't necessary anymore for all devices

# One UI 7 additions
ENTRIES="
attiqi_app
attiqi_app_data_file
ker_app
kpp_app
kpp_data_file
"

# One UI 6.1.1 additions
ENTRIES+="
hal_dsms_default
hal_dsms_default_exec
proc_compaction_proactiveness
sbauth
sbauth_exec
"

# One UI 5.1.1 additions
ENTRIES+="
audiomirroring
audiomirroring_exec
audiomirroring_service
fabriccrypto
fabriccrypto_exec
fabriccrypto_data_file
hal_dsms_service
uwb_regulation_skip_prop
"

# [
GET_SYSTEM_EXT()
{
    if $TARGET_HAS_SYSTEM_EXT; then
        echo -n "system_ext"
    else
        echo -n "system/system/system_ext"
    fi
}

CIL_NAME="$(cat "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt")"

GET_VENDOR_API()
{
    echo "$(echo $CIL_NAME | sed 's/\.0//' )"
}

VENDOR_API_LIST="$(find "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/" -type f  -exec basename {} \; | \
                    sed '/.compat./d' | sed 's/\.cil//' | sed 's/\.0//' | sort)"
# ]

for e in $ENTRIES; do
    if grep -E -q "\($e\)" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/$CIL_NAME.cil" || \
         grep -E -q "${e}_$(GET_VENDOR_API)" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/$CIL_NAME.cil" || \
         grep -E -q " $e " "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/$CIL_NAME.cil"; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if ! grep -E -q "\(type $e\)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
            # the problematic entry is not supported by the target device
            echo "$e SELinux entry not supported. Removing"
            sed -i "/($e)/d" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/$CIL_NAME.cil"
            sed -i " $e " "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/$CIL_NAME.cil"
            for a in $VENDOR_API_LIST; do
                sed -i "/${e}_${a}/d" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping/$CIL_NAME.cil"
            done
            if grep -E -q "genfscon.*$e" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_sepolicy.cil"
            fi
        fi
    fi
done
