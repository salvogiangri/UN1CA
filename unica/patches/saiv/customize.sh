TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

DELETE_FROM_WORK_DIR "system" "system/saiv"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/saiv" 0 0 755 "u:object_r:system_file:s0"

# SEC_PRODUCT_FEATURE_CAMERA_CONFIG_DOCUMENT_DEWARP_VERSION
if [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_DOCUMENTSCAN_SOLUTIONS")" == *"AI_DEWARPING"* ]]; then
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" \
        "system" "system/saiv/image_understanding/db/smartscan_rectifier" 0 0 755 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" \
        "vendor" "saiv/image_understanding/db/smartscan_rectifier" 0 2000 755 "u:object_r:vendor_snap_file:s0"
else
    if [ -d "$WORK_DIR/system/system/saiv/image_understanding/db/smartscan_rectifier" ]; then
        DELETE_FROM_WORK_DIR "system" "system/saiv/image_understanding/db/smartscan_rectifier"
    fi
    if [ -d "$WORK_DIR/vendor/saiv/image_understanding/db/smartscan_rectifier" ]; then
        DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/smartscan_rectifier"
    fi
fi

# SEC_PRODUCT_FEATURE_VISION_CONFIG_FACE_RECOGNITION_SOLUTION
if [[ "$(GET_FLOATING_FEATURE_CONFIG "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/floating_feature.xml" "SEC_FLOATING_FEATURE_GALLERY_CONFIG_FACE_CLUSTER_VERSION")" != "SRCB_V5" ]] && \
        [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_GALLERY_CONFIG_FACE_CLUSTER_VERSION")" == "SRCB_V5" ]]; then
    if [[ -d "$WORK_DIR/system/system/saiv/face/cluster_pb" ]]; then
        DELETE_FROM_WORK_DIR "system" "system/saiv/face/cluster_pb"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/saiv/face/cluster_pb" 0 0 755 "u:object_r:system_file:s0"
fi

# SEC_PRODUCT_FEATURE_GALLERY_CONFIG_IMAGE_TAGGER_VERSION
if [[ "$(GET_FLOATING_FEATURE_CONFIG "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/floating_feature.xml" "SEC_FLOATING_FEATURE_GALLERY_CONFIG_IMAGE_TAGGER_VERSION")" != "V901" ]] && \
        [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_GALLERY_CONFIG_IMAGE_TAGGER_VERSION")" == "V901" ]]; then
    if [[ -d "$WORK_DIR/vendor/saiv/image_understanding/db/aig_document_detector" ]]; then
        DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/aig_document_detector"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "saiv/image_understanding/db/aig_document_detector" 0 2000 755 "u:object_r:vendor_snap_file:s0"
    if [[ -d "$WORK_DIR/vendor/saiv/image_understanding/db/aig_document_classifier" ]]; then
        DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/aig_document_classifier"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "saiv/image_understanding/db/aig_document_classifier" 0 2000 755 "u:object_r:vendor_snap_file:s0"
    if [[ -d "$WORK_DIR/vendor/saiv/image_understanding/db/aig_classifier" ]]; then
        DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/aig_classifier"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "saiv/image_understanding/db/aig_classifier" 0 2000 755 "u:object_r:vendor_snap_file:s0"
    if [[ -d "$WORK_DIR/system/system/saiv/image_understanding/db/aig" ]]; then
        DELETE_FROM_WORK_DIR "system" "system/saiv/image_understanding/db/aig"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/saiv/image_understanding/db/aig" 0 0 755 "u:object_r:system_file:s0"
fi

# SEC_PRODUCT_FEATURE_CAMERA_CONFIG_STRIDE_OCR_VERSION
if [[ -d "$WORK_DIR/system/system/saiv/textrecognition" ]]; then
    DELETE_FROM_WORK_DIR "system" "system/saiv/textrecognition"
fi
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/saiv/textrecognition" 0 0 755 "u:object_r:system_file:s0"

if [[ -d "$WORK_DIR/system/system/saiv/str" ]]; then
    DELETE_FROM_WORK_DIR "system" "system/saiv/str"
fi
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/saiv/str" 0 0 755 "u:object_r:system_file:s0"
