#!/bin/bash

# Identificação do Dispositivo
TARGET_NAME="Galaxy A15 4G"
TARGET_CODENAME="a155m"
TARGET_DEVICE="a15"
TARGET_PLATFORM="mt6789"
TARGET_ARCH="arm64"

# Base do Sistema
TARGET_PLATFORM_SDK_VERSION=35 # Android 15
TARGET_FIRMWARE_VER="A155MXXU3BX..." # Ajuste para a versão do firmware que você baixou

# Configurações de Partição (Valores exatos do seu BoardConfig)
TARGET_SUPER_PARTITION_SIZE=9126805504
TARGET_DYNAMIC_PARTITIONS_SIZE=9122611200 # Group size do samsung_dynamic_partitions
TARGET_FLASH_BLOCK_SIZE=131072

# Formato de Arquivo (Importante: Seu BoardConfig usa EROFS)
TARGET_SYSTEM_FS_TYPE="erofs"
TARGET_VENDOR_FS_TYPE="erofs"
TARGET_PRODUCT_FS_TYPE="erofs"
TARGET_SYSTEM_EXT_FS_TYPE="erofs"

# Kernel & Boot
TARGET_BOOT_HEADER_VERSION=4
TARGET_KERNEL_IMAGE_NAME="Image.gz"
TARGET_USES_VENDOR_BOOT=true # Seu BoardConfig indica BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT

# Funcionalidades One UI
TARGET_DISABLE_LIVE_BLUR=true # Necessário para o Helio G99 não engasgar
TARGET_ENABLE_HIGH_END_ANIMATIONS=true
