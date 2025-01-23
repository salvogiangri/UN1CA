#!/bin/bash

# F-Droid Mod Installation Script

# Function to copy local APKs and files to WORK_DIR
cd unica/mods/fdroid
ADD_LOCAL_APK()
{
    local APK_PATH="$1"
    local DEST_PATH="$2"
    echo "Current path: $(pwd)"
	
    echo "Adding $(basename "$APK_PATH") to $DEST_PATH"
    mkdir -p "$WORK_DIR/system/system/$(dirname "$DEST_PATH")"
    cp -a "$APK_PATH" "$WORK_DIR/system/system/$DEST_PATH"
}

# Adding F-Droid APKs and associated files

ADD_LOCAL_APK "system/priv-app/F-DroidPrivilegedExtension/F-DroidPrivilegedExtension.apk" "priv-app/F-DroidPrivilegedExtension/F-DroidPrivilegedExtension.apk"
ADD_LOCAL_APK "system/etc/permissions/permissions_org.fdroid.fdroid.privileged.xml" "etc/permissions/permissions_org.fdroid.fdroid.privileged.xml"

# Check if entry exists in file_context-system
if ! grep -q "Fdroid" "$WORK_DIR/configs/file_context-system"; then
  {
    echo "/system/priv-app/F-DroidPrivilegedExtension/F-DroidPrivilegedExtension\.apk u:object_r:system_file:s0"
    echo "/system/priv-app/F-DroidPrivilegedExtension u:object_r:system_file:s0"
    echo "/system/etc/permissions/permissions_org\.fdroid\.fdroid\.privileged\.xml u:object_r:system_file:s0"
  } >> "$WORK_DIR/configs/file_context-system"
fi

# Check if entry exists in fs_config-system
if ! grep -q "Fdroid" "$WORK_DIR/configs/fs_config-system"; then
  {
    echo "system/etc/permissions/permissions_org.fdroid.fdroid.privileged.xml 0 0 644 capabilities=0x0"
    echo "system/priv-app/F-DroidPrivilegedExtension/F-DroidPrivilegedExtension.apk 0 0 644 capabilities=0x0"
    echo "system/priv-app/F-DroidPrivilegedExtension 0 0 755 capabilities=0x0"
  } >> "$WORK_DIR/configs/fs_config-system"
fi

echo "F-Droid mod has been successfully added!"
