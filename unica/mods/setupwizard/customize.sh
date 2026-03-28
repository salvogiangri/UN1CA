# shellcheck shell=bash
DECODE_APK "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk"

LOG "- Enabling navigation bar type settings step"
SMALI_PATCH "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk" \
    "smali/S2/f.smali" "replace" \
    "d(Landroid/content/Context;Z)Ljava/util/ArrayList;" \
    "navigationbar_setting" \
    "this_string_does_not_exist" \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk" \
    "smali/com/sec/android/app/SecSetupWizard/SecSetupWizardActivity.smali" "replace" \
    "f(Ljava/lang/String;)Z" \
    "navigationbar_setting" \
    "this_string_does_not_exist" \
    > /dev/null

LOG "- Disabling Recommended apps step"
EVAL "sed -i \"/omcagent/d\" \"$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/res/values/arrays.xml\""

# Dynamically patch SecSetupWizard_Global
# - Add missing/non-xml files in place
# - Patch existing files
#   - Use the first line of the file to tell sed how to apply the rest of the content
#   - Exception made for files under *res/values* where the "resources" tag gets nuked
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSetupWizard_Global.apk\//}"

    if [ ! -f "$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/$f" ] || \
            [[ "$f" != *".xml" ]]; then
        LOG "- Adding \"$f\" to /system/system/priv-app/SecSetupWizard_Global.apk"
        EVAL "mkdir -p \"$(dirname "$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/$f")\""
        EVAL "cp -a \"$MODPATH/SecSetupWizard_Global.apk/${f//\$/\\$}\" \"$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/${f//\$/\\$}\""
    else
        LOG "- Patching \"$f\" in /system/system/priv-app/SecSetupWizard_Global.apk"
        if [[ "$f" == *"res/values"* ]]; then
            PATCH_INST="/<\/resources>/i"
            CONTENT="$(sed -e "/?xml/d" -e "/resources>/d" "$MODPATH/SecSetupWizard_Global.apk/$f")"
        else
            PATCH_INST="$(head -n 1 "$MODPATH/SecSetupWizard_Global.apk/$f")"
            CONTENT="$(tail -n +2 "$MODPATH/SecSetupWizard_Global.apk/$f")"
        fi
        CONTENT="$(sed -e "s/\"/\\\\\"/g" -e "s/\\\\\\\\\"/\\\\\\\\\\\\\\\\\\\\\"/g" -e "s/\\$/\\\\$/g" -e "s/ /\\\ /g" -e "s/\\\\n/\\\\\\\\\n/g" <<< "$CONTENT")"
        CONTENT="$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$CONTENT")"
        EVAL "sed -i \"$PATCH_INST $CONTENT\" \"$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/$f\""
    fi
done < <(find "$MODPATH/SecSetupWizard_Global.apk" -type f)

unset PATCH_INST CONTENT
