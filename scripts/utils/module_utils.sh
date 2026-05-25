# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/smali_utils.sh"
# ]

# ABORT <message>
# Stops the build process, additionally prints a log message if supplied.
ABORT()
{
    if [ "$1" ]; then
        LOGE "$1"
    fi
    return 1
}

# ADD_JAR_TO_CLASSPATH "<system classpath/file>" "<classpath scope>" "<jar path>" [--min-sdk/-m <minimum sdk>] [--max-sdk/-m <maximum sdk>]
# Adds the given jar to the classpath and with the given scope and, optionally, sdk versions.
#
# System classpath can be any value from: bootclasspath, systemserverclasspath. Alternatively, an arbitrary Proto-encoded classpath file can be provided.
# Scope can be any value from: UNKNOWN, BOOTCLASSPATH, SYSTEMSERVERCLASSPATH, DEX2OATBOOTCLASSPATH or STANDALONE_SYSTEMSERVER_JARS.
# Jar path is the absolute path on the Android device filesystem of the jar file to load.
#
# "--min-sdk <minimum sdk>" or "-m <minimum sdk>" can be used to specify the minimum API level that the jar file supports.
# "--max-sdk <maximum sdk>" or "-M <maximum sdk>" can be used to specify the maximum API level that the jar file supports.
ADD_JAR_TO_CLASSPATH()
{
    # Check the required parameters
    _CHECK_NON_EMPTY_PARAM "FILE" "$1"
    _CHECK_NON_EMPTY_PARAM "SCOPE" "$2"
    _CHECK_NON_EMPTY_PARAM "JAR_PATH" "$3"

    local FILE="$1"; shift
    local SCOPE="$1"; shift
    local JAR_PATH="$1"; shift
    local MIN_SDK
    local MAX_SDK
    local PROTO="$SRC_DIR/prebuilts/proto/classpaths.proto"
    local CMD

    # Handle file parameter
    if [[ "$FILE" == "bootclasspath" ]]; then
        FILE="$WORK_DIR/system/system/etc/classpaths/bootclasspath.pb"
    elif [[ "$FILE" == "systemserverclasspath" ]]; then
        FILE="$WORK_DIR/system/system/etc/classpaths/systemserverclasspath.pb"
    fi

    if [ ! -f "$FILE" ]; then
        LOGE "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    # Handle scope parameter
    if [[ "$SCOPE" != "UNKNOWN" ]] && [[ "$SCOPE" != "BOOTCLASSPATH" ]] && [[ "$SCOPE" != "SYSTEMSERVERCLASSPATH" ]] && \
            [[ "$SCOPE" != "DEX2OATBOOTCLASSPATH" ]] && [[ "$SCOPE" != "STANDALONE_SYSTEMSERVER_JARS" ]]; then
        LOGE "\"$SCOPE\" is not a valid scope"
        return 1
    fi

    # Handle SDK parameters
    while [[ "$1" == "-"* ]]; do
        if [[ "$1" == "--min-sdk" ]] || [[ "$1" == "-m" ]]; then
            shift; MIN_SDK="$1"
        elif [[ "$1" == "--max-sdk" ]] || [[ "$1" == "-M" ]]; then
            shift; MAX_SDK="$1"
        else
            LOGE "Unknown option: $1"
            return 1
        fi
        shift
    done

    if [ -n "$MIN_SDK" ] && ! echo "$MIN_SDK" | grep -qE '^[0-9]+$'; then
        LOGE "Minimum sdk is not a valid integer: $MIN_SDK"
    fi

    if [ -n "$MAX_SDK" ] && ! echo "$MAX_SDK" | grep -qE '^[0-9]+$'; then
        LOGE "Maximum sdk is not a valid integer: $MAX_SDK"
    fi

    # Decode given binary file to text
    EVAL "cd \"$(dirname "$FILE")\"; protoc --decode=ExportedClasspathsJars --proto_path=\"$(dirname "$PROTO")\" \"$(basename "$PROTO")\" < \"$(basename "$FILE")\" > \"$(basename "$FILE").txt\""

    local TXT_FILE="$(dirname "$FILE")/$(basename "$FILE").txt"

    # Handle locations which can be written in two different ways
    # system_ext/vendor/product are both present via symlink to / and /system
    local NORMALIZED_JAR_PATH="$JAR_PATH"
    if [[ "$NORMALIZED_JAR_PATH" == "/system/vendor/"* ]]; then
        NORMALIZED_JAR_PATH="/vendor${NORMALIZED_JAR_PATH#/system/vendor}"
    elif [[ "$NORMALIZED_JAR_PATH" == "/system/product/"* ]]; then
        NORMALIZED_JAR_PATH="/product${NORMALIZED_JAR_PATH#/system/product}"
    elif [[ "$NORMALIZED_JAR_PATH" == "/system/system_ext/"* ]]; then
        NORMALIZED_JAR_PATH="/system_ext${NORMALIZED_JAR_PATH#/system/system_ext}"
    fi

    # Search the decoded file line by line for a block whose path+scope matches what we are adding.
    # For each block we track: whether we are inside a block, the start line, the parsed path and scope.
    local LINE_NUMBER=0
    local IN_BLOCK="false"
    local BLOCK_START_LINE=0
    local BLOCK_END_LINE=0
    local CURRENT_PATH=""
    local CURRENT_SCOPE=""
    local MATCH_START_LINE=0
    local MATCH_END_LINE=0

    while IFS= read -r LINE; do
        LINE_NUMBER=$(( LINE_NUMBER + 1 ))

        if [[ "$LINE" == "jars {"* ]]; then
            IN_BLOCK="true"
            BLOCK_START_LINE=$LINE_NUMBER
            CURRENT_PATH=""
            CURRENT_SCOPE=""
            continue
        fi

        if [[ "$IN_BLOCK" == "true" ]] && [[ "$LINE" == "}" ]]; then
            IN_BLOCK="false"
            BLOCK_END_LINE=$LINE_NUMBER

            # Normalize the path found in this block the same way we normalized JAR_PATH above
            local NORMALIZED_CURRENT_PATH="$CURRENT_PATH"
            if [[ "$NORMALIZED_CURRENT_PATH" == "/system/vendor/"* ]]; then
                NORMALIZED_CURRENT_PATH="/vendor${NORMALIZED_CURRENT_PATH#/system/vendor}"
            elif [[ "$NORMALIZED_CURRENT_PATH" == "/system/product/"* ]]; then
                NORMALIZED_CURRENT_PATH="/product${NORMALIZED_CURRENT_PATH#/system/product}"
            elif [[ "$NORMALIZED_CURRENT_PATH" == "/system/system_ext/"* ]]; then
                NORMALIZED_CURRENT_PATH="/system_ext${NORMALIZED_CURRENT_PATH#/system/system_ext}"
            fi

            if [[ "$NORMALIZED_CURRENT_PATH" == "$NORMALIZED_JAR_PATH" ]] && [[ "$CURRENT_SCOPE" == "$SCOPE" ]]; then
                MATCH_START_LINE=$BLOCK_START_LINE
                MATCH_END_LINE=$BLOCK_END_LINE
                break
            fi
            continue
        fi

        if [[ "$IN_BLOCK" == "true" ]]; then
            if [[ "$LINE" == "  path:"* ]];            then CURRENT_PATH="$(echo "$LINE" | cut -d'"' -f2)"; fi
            if [[ "$LINE" == "  classpath:"* ]];       then CURRENT_SCOPE="$(echo "$LINE" | awk '{print $2}')"; fi
        fi
    done < "$TXT_FILE"

    if [[ "$MATCH_START_LINE" -gt 0 ]]; then
        LOG "- Entry already present, removing it."
        sed -i "${MATCH_START_LINE},${MATCH_END_LINE}d" "$TXT_FILE"
    fi

    # Add to the text file
    LOG "- Adding \"$JAR_PATH\" classpath entry to \"${FILE//$WORK_DIR/}\" with \"$SCOPE\" scope"
    {
        echo "jars {"
        echo "  path: \"$JAR_PATH\""
        echo "  classpath: $SCOPE"
        if [ "$MIN_SDK" ]; then
            echo "  min_sdk_version: \"$MIN_SDK\""
        fi
        if [ "$MAX_SDK" ]; then
        echo "  max_sdk_version: \"$MAX_SDK\""
        fi
        echo "}"
    } >> "$(dirname "$FILE")/$(basename "$FILE").txt"

    # Encode back text file to binary
    CMD="cd \"$(dirname "$FILE")\"; protoc --encode=ExportedClasspathsJars --proto_path=\"$(dirname "$PROTO")\" \"$(basename "$PROTO")\" < \"$(basename "$FILE").txt\" > \"$(basename "$FILE")\""
    EVAL "$CMD"
    EVAL "rm \"$(dirname "$FILE")/$(basename "$FILE").txt\""
}

# APPLY_PATCH <partition> <apk/jar> <patch>
# Applies a unified diff patch to the provided APK/JAR decoded directory.
APPLY_PATCH()
{
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$1" || return 1
    _CHECK_NON_EMPTY_PARAM "FILE" "$2" || return 1
    _CHECK_NON_EMPTY_PARAM "PATCH" "$3" || return 1

    local PARTITION="$1"
    local FILE="$2"
    local PATCH="$3"

    if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
        LOGE "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    if [ ! -f "$PATCH" ]; then
        LOGE "File not found: ${PATCH//$SRC_DIR\//}"
        return 1
    fi

    while [[ "${FILE:0:1}" == "/" ]]; do
        FILE="${FILE:1}"
    done

    DECODE_APK "$PARTITION" "$FILE" || return 1

    LOG "- Applying \"$(grep "^Subject:" "$PATCH" | sed "s/.*PATCH] //")\" to /$PARTITION/$FILE"
    EVAL "LC_ALL=C git apply --directory=\"$APKTOOL_DIR/$PARTITION/${FILE//system\//}\" --verbose --unsafe-paths \"$PATCH\"" || return 1
}

# DECODE_APK <partition> <apk/jar>
# Same usage as `run_cmd apktool d <partition> <apk/jar>`.
DECODE_APK()
{
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$1" || return 1
    _CHECK_NON_EMPTY_PARAM "FILE" "$2" || return 1

    if [ ! -d "$APKTOOL_DIR/$1/${2//system\/}" ]; then
        "$SRC_DIR/scripts/apktool.sh" d "$1" "$2"
        return $?
    fi

    return 0
}

# GET_GALAXY_STORE_DOWNLOAD_URL "<package name/id>"
# Returns a URL to download the desidered app from Samsung servers.
GET_GALAXY_STORE_DOWNLOAD_URL()
{
    _CHECK_NON_EMPTY_PARAM "PACKAGE" "$1" || return 1

    local PACKAGE="$1"
    local DEVICES
    local OS
    local ONEUI
    local PROTOCOL

    # Galaxy S25 Ultra EUR_OPENX
    # Galaxy S22 Ultra GBL_OPENX
    DEVICES=("SM-S938B" "SM-S901E")

    OS="$(GET_PROP "system" "ro.build.version.sdk")"
    ONEUI="$(GET_PROP "system" "ro.build.version.oneui")"

    if [ ! "$OS" ]; then
        # Fallback to Android 16
        OS="36"
    fi
    if [ ! "$ONEUI" ]; then
        # Fallback to One UI 8.0
        ONEUI="80000"
    fi

    PROTOCOL+="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>"
    PROTOCOL+="<SamsungProtocol networkType=\"0\" openApiVersion=\"$OS\" deviceModel=\"DEVICE\""
    PROTOCOL+=" mcc=\"262\" mnc=\"01\" csc=\"EUX\" version=\"7.7\""
    PROTOCOL+=" deviceFeature=\"locale=en_GB||abi32=armeabi-v7a:armeabi||abi64=arm64-v8a||oneUiVersion=$ONEUI\">"
    PROTOCOL+="<request id=\"2303\" numParam=\"2\">"
    PROTOCOL+="<param name=\"stduk\">0</param>"
    PROTOCOL+="<param name=\"productID\">PRODUCTID</param>"
    PROTOCOL+="</request>"
    PROTOCOL+="</SamsungProtocol>"

    local OUT
    local REQUEST
    for i in "${DEVICES[@]}"; do
        if [[ "$PACKAGE" =~ ^[+-]?[0-9]+$ ]]; then
            OUT="$PACKAGE"
        else
            OUT="$(curl -L -s "https://vas.samsungapps.com/stub/stubUpdateCheck.as?appId=$PACKAGE&versionCode=0&deviceId=$i&mcc=262&mnc=01&csc=EUX&sdkVer=$OS&oneUiVersion=$ONEUI&systemId=0")"
            OUT="$(grep -o -P "(?<=<productId>)[^<]+" <<< "$OUT")"
            if [ ! "$OUT" ]; then
                continue
            fi
        fi

        REQUEST="$PROTOCOL"
        REQUEST="${REQUEST//DEVICE/$i}"
        REQUEST="${REQUEST//PRODUCTID/$OUT}"

        OUT="$(curl -L -s "https://uk-odc.samsungapps.com/ods.as" -H "Content-Type: text/plain" -d "$REQUEST")"
        OUT="$(grep -o -P "(?<=<value name=\"downLoadURI\">)[^<]+" <<< "$OUT")"
        if [ "$OUT" ]; then
            echo "${OUT//amp;/}"
            return 0
        fi
    done

    LOGE "No download URI found for app \"$PACKAGE\""
    return 1
}

# GET_FLOATING_FEATURE_CONFIG "<file>" "<config>"
# Returns the supplied config value, file can be omitted.
GET_FLOATING_FEATURE_CONFIG()
{
    local FILE
    if [ "$2" ]; then
        FILE="$1"
        shift
    else
        FILE="$WORK_DIR/system/system/etc/floating_feature.xml"
    fi

    _CHECK_NON_EMPTY_PARAM "CONFIG" "$1" || return 1

    local CONFIG="$1"

    if [ ! -f "$FILE" ]; then
        LOGE "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    grep -o -P "(?<=<$CONFIG>)[^<]+" "$FILE" 2> /dev/null || true
}

# HEX_PATCH "<file>" "<old pattern>" "<new pattern>"
# Applies the supplied hex patch to the desidered file.
HEX_PATCH()
{
    _CHECK_NON_EMPTY_PARAM "FILE" "$1" || return 1
    _CHECK_NON_EMPTY_PARAM "FROM" "$2" || return 1
    _CHECK_NON_EMPTY_PARAM "TO" "$3" || return 1

    local FILE="$1"
    local FROM="$2"
    local TO="$3"

    if [ ! -f "$FILE" ]; then
        LOGE "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    FROM="${FROM// /}"
    TO="${TO// /}"

    FROM="$(tr "[:upper:]" "[:lower:]" <<< "$FROM")"
    TO="$(tr "[:upper:]" "[:lower:]" <<< "$TO")"

    if ! xxd -p -c 0 "$FILE" | grep -q "$FROM"; then
        LOGE "No \"$FROM\" match in ${FILE//$WORK_DIR/}"
        return 1
    fi

    if [[ "$(echo -n "$FROM" | wc -c)" != "$(echo -n "$TO" | wc -c)" ]]; then
        LOGE "Byte strings length must be equal"
        return 1
    fi

    LOG "- Patching \"$FROM\" to \"$TO\" in ${FILE//$WORK_DIR/}"
    xxd -p -c 0 "$FILE" | sed "s/$FROM/$TO/" | xxd -r -p > "$FILE.tmp"
    mv "$FILE.tmp" "$FILE"

    return 0
}

# SET_FLOATING_FEATURE_CONFIG "<config>" "<value>"
# Sets the supplied config to the desidered value.
# "-d" or "--delete" can be passed as value to delete the config.
SET_FLOATING_FEATURE_CONFIG()
{
    _CHECK_NON_EMPTY_PARAM "CONFIG" "$1" || return 1
    _CHECK_NON_EMPTY_PARAM "VALUE" "$2" || return 1

    local CONFIG="$1"
    local VALUE="$2"
    local FILE="$WORK_DIR/system/system/etc/floating_feature.xml"

    if [ ! -f "$FILE" ]; then
        LOGE "File not found: ${FILE//$WORK_DIR/}"
        return 1
    fi

    if grep -q "$CONFIG" "$FILE"; then
        if [[ "$VALUE" == "-d" ]] || [[ "$VALUE" == "--delete" ]]; then
            LOG "- Deleting \"$CONFIG\" config in /system/system/etc/floating_feature.xml"
            sed -i "/<$CONFIG>/d" "$FILE"
        else
            LOG "- Replacing \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
            sed -i "$(sed -n "/<${CONFIG}>/=" "$FILE") c\ \ \ \ <${CONFIG}>${VALUE}</${CONFIG}>" "$FILE"
        fi
    elif [[ "$VALUE" != "-d" ]] && [[ "$VALUE" != "--delete" ]]; then
        LOG "- Adding \"$CONFIG\" config with \"$VALUE\" in /system/system/etc/floating_feature.xml"
        sed -i "/<\/SecFloatingFeatureSet>/d" "$FILE"
        if ! grep -q "Added by scripts" "$FILE"; then
            echo "    <!-- Added by scripts/utils/module_utils.sh -->" >> "$FILE"
        fi
        echo "    <${CONFIG}>${VALUE}</${CONFIG}>" >> "$FILE"
        echo "</SecFloatingFeatureSet>" >> "$FILE"
    fi

    return 0
}

# SET_PROP_IF_DIFF "<partition>" "<prop>" "<value>"
# Calls SET_PROP if the current prop value does not match, partition name CANNOT be omitted.
SET_PROP_IF_DIFF()
{
    _CHECK_NON_EMPTY_PARAM "PARTITION" "$1" || return 1
    _CHECK_NON_EMPTY_PARAM "PROP" "$2" || return 1
    _CHECK_NON_EMPTY_PARAM "EXPECTED" "$3" || return 1

    local PARTITION="$1"
    local PROP="$2"
    local EXPECTED="$3"

    if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
        LOGE "\"$PARTITION\" is not a valid partition name"
        return 1
    fi

    local CURRENT
    CURRENT="$(GET_PROP "$PARTITION" "$PROP")"
    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || SET_PROP "$PARTITION" "$PROP" "$EXPECTED"
}
