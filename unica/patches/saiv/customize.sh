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

# SEC_PRODUCT_FEATURE_GALLERY_CONFIG_PET_CLUSTER_VERSION
if [[ "$(GET_FLOATING_FEATURE_CONFIG "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/floating_feature.xml" "SEC_FLOATING_FEATURE_GALLERY_CONFIG_PET_CLUSTER_VERSION")" != "V1001" ]] && \
        [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_GALLERY_CONFIG_PET_CLUSTER_VERSION")" == "V1001" ]]; then
    if [[ -d "$WORK_DIR/vendor/saiv/image_understanding/db/pet_detector" ]]; then
        DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/pet_detector"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "saiv/image_understanding/db/pet_detector" 0 2000 755 "u:object_r:vendor_snap_file:s0"
    if [[ -d "$WORK_DIR/vendor/saiv/image_understanding/db/pet_mypetsearch" ]]; then
        DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/pet_mypetsearch"
    fi
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "saiv/image_understanding/db/pet_mypetsearch" 0 2000 755 "u:object_r:vendor_snap_file:s0"
fi

# SEC_PRODUCT_FEATURE_VISION_CONFIG_BIXBYVISION_VERSION
if [[ -f "$WORK_DIR/system/system/priv-app/BixbyVisionFramework3.5/BixbyVisionFramework3.5.apk" ]]; then
    if [[ ! -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/slens_classifier" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/slens_classifier" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "etc/saiv/image_understanding/db/slens_classifier"
        fi
        ADD_TO_WORK_DIR "gts11xx" "vendor" "etc/saiv/image_understanding/db/slens_classifier/slens_classifier_cnn.tflite" 0 0 644 "u:object_r:vendor_configs_file:s0"
        if [[ -d "$WORK_DIR/system/system/saiv/image_understanding/db/slens_classifier" ]]; then
            DELETE_FROM_WORK_DIR "system" "system/saiv/image_understanding/db/slens_classifier"
        fi
        ADD_TO_WORK_DIR "gts11xx" "system" "system/saiv/image_understanding/db/slens_classifier/slens_classifier_cnn.sni" 0 0 644 "u:object_r:system_file:s0"
    fi
    if [[ ! -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/slens_detector" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/slens_detector" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "etc/saiv/image_understanding/db/slens_detector"
        fi
        ADD_TO_WORK_DIR "gts11xx" "vendor" "etc/saiv/image_understanding/db/slens_detector/slens_detector_cnn.tflite" 0 0 644 "u:object_r:vendor_configs_file:s0"
        if [[ -d "$WORK_DIR/system/system/saiv/image_understanding/db/slens_detector" ]]; then
            DELETE_FROM_WORK_DIR "system" "system/saiv/image_understanding/db/slens_detector"
        fi
        ADD_TO_WORK_DIR "gts11xx" "system" "system/saiv/image_understanding/db/slens_detector/slens_detector_cnn.sni" 0 0 644 "u:object_r:system_file:s0"
    fi
fi

if [[ -f "$WORK_DIR/system/system/priv-app/PhotoEditor_AIFull/PhotoEditor_AIFull.apk" ]]; then
    if [[ ! -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/hs_segmenter" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/hs_segmenter" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "etc/saiv/image_understanding/db/hs_segmenter"
        fi
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/saiv/image_understanding/db/hs_segmenter/hs_segmenter.tflite" 0 0 644 "u:object_r:vendor_configs_file:s0"
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/saiv/image_understanding/db/hs_segmenter/hs_segmenter.info" 0 0 644 "u:object_r:vendor_configs_file:s0"
    fi
fi

if [[ -f "$WORK_DIR/system/system/lib64/libsmart_cropping.camera.samsung.so" ]]; then
    if [[ ! -d "$WORK_DIR/system/system/saiv/smartcropping_2.0" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/system/system/saiv/smartcropping_2.0" ]]; then
            DELETE_FROM_WORK_DIR "system" "system/saiv/smartcropping_2.0"
        fi
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/saiv/smartcropping_2.0/db/smartcrop_saliency_deploy.prototxt" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/saiv/smartcropping_2.0/db/smartcrop_saliency_train" 0 0 644 "u:object_r:system_file:s0"
    fi
fi

if [[ -f "$WORK_DIR/system/system/lib64/libImageCropper.camera.samsung.so" ]]; then
    if [[ ! -d "$WORK_DIR/vendor/saiv/image_understanding/db/sce_detector" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/saiv/image_understanding/db/sce_detector" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "saiv/image_understanding/db/sce_detector"
        fi
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "saiv/image_understanding/db/sce_detector/sce_detector_cnn.tflite" 0 0 644 "u:object_r:vendor_snap_file:s0"
    fi
fi

if [[ -f "$WORK_DIR/system/system/lib64/libSmartScan.camera.samsung.so" ]]; then
    if [[ ! -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/SS_segmenter" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/etc/saiv/image_understanding/db/SS_segmenter" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "etc/saiv/image_understanding/db/SS_segmenter"
        fi
        ADD_TO_WORK_DIR "a34xxx" "vendor" "etc/saiv/image_understanding/db/SS_segmenter/SS_segmenter_cnn.tflite" 0 0 644 "u:object_r:vendor_configs_file:s0"
        ADD_TO_WORK_DIR "a34xxx" "vendor" "etc/saiv/image_understanding/db/SS_segmenter/SS_segmenter_cnn.info" 0 0 644 "u:object_r:vendor_configs_file:s0"
    fi
fi

# SEC_PRODUCT_FEATURE_CAMERA_SINGLETAKE_SOLUTIONS
if [[ -f "$WORK_DIR/system/system/cameradata/singletake/service-feature.xml" ]]; then
    if ! grep -q "ENABLE_SINGLE_TAKE_LITE.*true" "$WORK_DIR/system/system/cameradata/singletake/service-feature.xml" 2>/dev/null; then
        if [[ ! -d "$WORK_DIR/vendor/etc/singletake/SmartCrop" ]] || \
                [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
            if [[ -d "$WORK_DIR/vendor/etc/singletake/SmartCrop" ]]; then
                DELETE_FROM_WORK_DIR "vendor" "etc/singletake/SmartCrop"
            fi
            ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/singletake/SmartCrop" 0 2000 755 "u:object_r:vendor_configs_file:s0"
        fi
    fi
    if [[ ! -d "$WORK_DIR/vendor/etc/singletake/ClarityScorer" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/etc/singletake/ClarityScorer" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "etc/singletake/ClarityScorer"
        fi
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/singletake/ClarityScorer" 0 2000 755 "u:object_r:vendor_configs_file:s0"
    fi
fi

# SEC_PRODUCT_FEATURE_CAMERA_CONFIG_ACTION_CLASSIFIER
if [[ -f "$WORK_DIR/system/system/lib64/libVideoClassifier.camera.samsung.so" ]]; then
    if [[ ! -d "$WORK_DIR/vendor/etc/singletake/dynamic_viewing" ]] || \
            [[ "$TARGET_PLATFORM_SDK_VERSION" -lt "$SOURCE_PLATFORM_SDK_VERSION" ]]; then
        if [[ -d "$WORK_DIR/vendor/etc/singletake/dynamic_viewing" ]]; then
            DELETE_FROM_WORK_DIR "vendor" "etc/singletake/dynamic_viewing"
        fi
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/singletake/dynamic_viewing" 0 2000 755 "u:object_r:vendor_configs_file:s0"
    fi
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
