# [
GET_PROP()
{
    local PROP="$1"
    local FILE="$2"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        exit 1
    fi

    grep "^$PROP=" "$FILE" | cut -d "=" -f2-
}

SET_PROP()
{
    local PROP="$1"
    local VALUE="$2"
    local FILE="$3"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        PROP="$(echo -n "$PROP" | sed 's/=//g')"
        if grep -Fq "$PROP" "$FILE"; then
            echo "Deleting \"$PROP\" prop in $FILE" | sed "s.$WORK_DIR..g"
            sed -i "/^$PROP/d" "$FILE"
        fi
    else
        if grep -Fq "$PROP" "$FILE"; then
            local LINES

            echo "Replacing \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            LINES="$(sed -n "/^${PROP}\b/=" "$FILE")"
            for l in $LINES; do
                sed -i "$l c${PROP}=${VALUE}" "$FILE"
            done
        else
            echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            if ! grep -q "Added by scripts" "$FILE"; then
                echo "# Added by scripts/internal/apply_modules.sh" >> "$FILE"
            fi
            echo "$PROP=$VALUE" >> "$FILE"
        fi
    fi
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

if [ -n "$(GET_PROP "ro.security.fips.ux" "$WORK_DIR/vendor/build.prop")" ]; then
    SET_PROP "ro.security.fips.ux" "Disabled" "$WORK_DIR/vendor/build.prop"
fi

REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/app/BlockchainBasicKit"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/bin/dualdard"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/init/dualdard.rc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/privapp-permissions-com.samsung.android.hdmapp.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/privapp-permissions-com.samsung.android.kgclient.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/privapp-permissions-com.samsung.android.knox.zt.framework.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/sysconfig/preinstalled-packages-com.samsung.android.coldwalletservice.xml"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/framework/service-samsung-blockchain.jar"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/android.hardware.weaver@1.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/hidl_tlc_blockchain_comm_client.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libdualdar.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libepm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libhermes_cred.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libkeyutils.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libknox_filemanager.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libpersona.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libtlc_blockchain_comm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libtlc_blockchain_keystore.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libtlc_blockchain_direct_comm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/vendor.samsung.hardware.tlc.blockchain@1.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/hidl_tlc_blockchain_comm_client.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libdualdar.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libtlc_blockchain_comm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libtlc_blockchain_keystore.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libtlc_blockchain_direct_comm.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.tlc.blockchain@1.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/HdmApk"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/KnoxAIFrameworkApp"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/KnoxGuard"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/KnoxZtFramework"
