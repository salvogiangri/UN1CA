#!/usr/bin/env bash
#
# Copyright (C) 2023 BlackMesa123
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -Ee

# [
GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://fota-cloud-dn.ospserver.net/firmware/$REGION/$MODEL/version.xml" \
        | grep latest | sed 's/^[^>]*>//' | sed 's/<.*//'
}
#]

if [ "$#" != 1 ]; then
    echo "Usage: update_prebuilt_blobs <path>"
    exit 1
fi

case "$1" in
    "unica/packages/china")
        MODULE="$1"
        FW="SM-S9110/CHC/RFCW2198XNF"
        BLOBS="$(find "$SRC_DIR/unica/packages/china/system" -type f | sed "s.$SRC_DIR/unica/packages/china.system.")"
        ;;
    "unica/packages/fod/essi")
        MODULE="$1"
        FW="SM-S901B/BTE/350330051234562"
        BLOBS="$(find "$SRC_DIR/unica/packages/fod/essi/system" -type f | sed "s.$SRC_DIR/unica/packages/fod/essi.system.")"
        ;;
    "unica/packages/fod/qssi")
        MODULE="$1"
        FW="SM-X716B/EUX/353439961234567"
        BLOBS="$(find "$SRC_DIR/unica/packages/fod/qssi/system" -type f | sed "s.$SRC_DIR/unica/packages/fod/qssi.system.")"
        ;;
    "unica/packages/knox/essi/none")
        MODULE="$1"
        FW="SM-A546B/BTE/350756481234568"
        BLOBS="$(find "$SRC_DIR/unica/packages/knox/essi/none/system" -type f | sed "s.$SRC_DIR/unica/packages/knox/essi/none.system.")"
        ;;
    "unica/packages/knox/qssi/none")
        MODULE="$1"
        FW="SM-A736B/INS/352828291234563"
        BLOBS="$(find "$SRC_DIR/unica/packages/knox/qssi/none/system" -type f | sed "s.$SRC_DIR/unica/packages/knox/qssi/none.system.")"
        ;;
    "unica/packages/knox/qssi/sdp")
        MODULE="$1"
        FW="SM-A528B/BTU/352599501234566"
        BLOBS="$(find "$SRC_DIR/unica/packages/knox/qssi/sdp/system" -type f | sed "s.$SRC_DIR/unica/packages/knox/qssi/sdp.system.")"
        ;;
    "unica/packages/mass_cam")
        MODULE="$1"
        FW="SM-A736B/INS/352828291234563"
        BLOBS="$(find "$SRC_DIR/unica/packages/mass_cam/system" -type f | sed "s.$SRC_DIR/unica/packages/mass_cam.system.")"
        ;;
    "unica/packages/vndk/30")
        MODULE="$1"
        FW="SM-A736B/INS/352828291234563"
        BLOBS="system/system/system_ext/apex/com.android.vndk.v30.apex"
        ;;
    "unica/packages/vndk/31")
        MODULE="$1"
        FW="SM-S901B/BTE/350330051234562"
        BLOBS="system/system/system_ext/apex/com.android.vndk.v31.apex"
        ;;
    #"unica/packages/vndk/32")
    #    MODULE="$1"
    #    FW="SM-F936B/BTE"
    #    BLOBS="system/system/system_ext/apex/com.android.vndk.v32.apex"
    #    ;;
    "unica/packages/vndk/33")
        MODULE="$1"
        FW="SM-S911B/INS/352404911234563"
        BLOBS="system_ext/apex/com.android.vndk.v33.apex"
        ;;
    "target/m52xq/patches/stock_blobs")
        MODULE="$1"
        FW="SM-A528B/BTU/352599501234566"
        BLOBS="$(find "$SRC_DIR/target/m52xq/patches/stock_blobs/product" -type f \
            | sed "s.$SRC_DIR/target/m52xq/patches/stock_blobs/product..")"
        BLOBS+="$(find "$SRC_DIR/target/m52xq/patches/stock_blobs/system" -type f \
            -not -path "*/etc/*" | sed "s.$SRC_DIR/target/m52xq/patches/stock_blobs.system.")"
        ;;
    "target/m52xq/patches/vendor")
        MODULE="$1"
        FW="SM-A528B/BTU/352599501234566"
        BLOBS="$(find "$SRC_DIR/target/m52xq/patches/vendor/vendor" -type f \
            -not -path "*/firmware/*" ! -name "*wifi_firmware.rc" | sed "s.$SRC_DIR/target/m52xq/patches/vendor/..")"
        ;;
    *)
        echo "Unsupported path: $1"
        exit 1
        ;;
esac

MODEL=$(echo -n "$FW" | cut -d "/" -f 1)
REGION=$(echo -n "$FW" | cut -d "/" -f 2)

[ -z "$(GET_LATEST_FIRMWARE)" ] && exit 1
if [[ "$(GET_LATEST_FIRMWARE)" == "$(cat "$SRC_DIR/$MODULE/.current")" ]]; then
    echo "Nothing to do."
    exit 0
fi

echo -e "Updating $MODULE blobs\n"

export SOURCE_FIRMWARE="$FW"
export TARGET_FIRMWARE="$FW"
bash "$SRC_DIR/scripts/download_fw.sh"
bash "$SRC_DIR/scripts/extract_fw.sh"

for i in $BLOBS; do
    if [[ "$i" == *"system_ext/apex/com.android.vndk.v"* ]]; then
        if [[ "$i" == *"com.android.vndk.v30.apex" ]]; then
            rm -rf "$SRC_DIR/unica/packages/vndk/30/com.android.vndk.v30.apex."*
            split -db 52428800 "$FW_DIR/${MODEL}_${REGION}/$i" \
                "$SRC_DIR/unica/packages/vndk/30/com.android.vndk.v30.apex."
        else
            cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$i" \
                "$SRC_DIR/$MODULE/$(basename "$i")"
        fi

        continue
    fi

    if [[ "$i" == "system/system/"* ]]; then
        cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$i" \
            "$SRC_DIR/$MODULE/$(echo "$i" | sed "s.system/system/.system/.")"
    elif [[ "$i" == "product/"* ]] || [[ "$i" == "vendor/"* ]]; then
        cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$i" \
            "$SRC_DIR/$MODULE/$i"
    fi
done

cp --preserve=all "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" "$SRC_DIR/$MODULE/.current"

exit 0
