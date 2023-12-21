---
layout: default
title: How the build system works
parent: Developer guides
nav_order: 1
---

# How the build system works
{: .pb-2 }
UN1CA build system is nothing more than a very big bash script, which in the end will automatically generate a flashable custom One UI ROM.

To make sure this build system is in its best possible state, there are a few principles to keep in mind while working on it:
- Making it as easy to use, code and maintain as possible
- Support for a wide variety of devices
- Being as modular as possible
- Update-proof

## Root directory
{: .pb-2 }
The main root directory has the following structure:

```tree
UN1CA
├── docs                <--- Documentation folder
├── external            <--- Dependencies folder
├── scripts             <--- Scripts folder
├── target              <--- Devices folder
├── out                 <--- Output directory
├── unica               <--- ROM folder
└── buildenv.sh         <--- Shell config script
```

### **external**
{: .pb-2 }
This folder contains all the tools that are required by the build system when working over the Android OS environment, which are:
- [android-tools](https://github.com/nmeum/android-tools): a standalone version of some of the AOSP CLI tools
- [apktool](https://github.com/iBotPeaches/Apktool): the Swiss Army knife to manipulate Android's APK/JAR files
- [erofs-utils](https://github.com/sekaiacg/erofs-utils): a fork of the original erofs-utils which also includes Android-specific code
- [ext4_utils](https://android.googlesource.com/platform/system/extras/+/refs/heads/main/ext4_utils/), [f2fs_utils](https://android.googlesource.com/platform/system/extras/+/refs/heads/main/f2fs_utils/): rip offs of some AOSP scripts required to generate system images
- [img2sdat](https://github.com/BlackMesa123/img2sdat): AOSP rip off used to generate flashable sparse data images
- [samfirm.js](https://github.com/DavidArsene/samfirm.js): utility that downloads Samsung firmwares straight from FUS (Firmware Update Server)
- [signapk](https://android.googlesource.com/platform/build/+/refs/heads/main/tools/signapk/): AOSP rip off used to sign APK/ZIP files

### **scripts**
{: .pb-2 }
This folder contains the whole set of scripts of the build system. A list of all the available commands can be seen by running `run_cmd`.

### **target**
{: .pb-2 }
This folder contains all the devices supported by UN1CA, each with its own build configuration and specific patches.

### **unica**
{: .pb-2 }
This folder contains the main ROM configuration file, along with all the mods/patches which are applied regardless of the device.

### buildenv.sh
{: .pb-2 }
When sourced, this script will automatically set up your current shell instance to build UN1CA, it will also add the `run_cmd` function. Usage of this script is:
```bash
. ./buildenv.sh <target>
```
With `<target>` being the device name. A list of all the available devices can be seen by running the command without any argument.

## Output directory
{: .pb-2 }
This folder is created when sourcing `buildenv.sh` for the first time. It has the following structure:

```tree
out
├── apktool
├── fw
├── odin
├── tools
├── work_dir
└── config.sh
```
{: .pb-2 }
- **apktool**: Folder containing all the decompiled APKs/JARs
- **fw**: Folder containing the extracted firmwares
- **odin**: Folder containing the downloaded firmwares
- **tools**: Folder containing all the compiled tools used by the build system
- **work_dir**: Work directory containing the ROM system files
- config.sh: Automatically generated build config

## Patching system
{: .pb-2 }
UN1CA patches structure is heavily inspired by the [Magisk/KernelSU modules](https://topjohnwu.github.io/Magisk/guides.html#magisk-modules) one:

```tree
patch
├── odm
├── product
├── system
├── system_ext
├── vendor
├── ...
├── smali
├── ...
├── customize.sh
├── ...
├── module.prop
├── ...
├── odm.prop
├── product.prop
├── system_ext.prop
├── system.prop
└── vendor.prop
```

### **module.prop**
{: .pb-2 }
This is the strict format of `module.prop`:
```
id=<patch identifier>
name=<patch name>
author=<patch author(s)>
description=<patch description>
```
Each property can be omitted, with the only requirement being the file existing.

### **Partitions folders (odm, product, system, system_ext, vendor)**
{: .pb-2 }
All the files placed inside one of each folder will be added/replaced inside each respective partition.
Please note new files will also need to be added as an entry in the file_context/fs_config configs to avoid issues when building the system images.

### **smali folder**
{: .pb-2 }
This folder allows the patching of APK/JAR files. A `patch` formatted file must be put inside a folder which path matches the path of the destination APK/JAR file to patch.

Example:
- APK files: `smali/system_ext/priv-app/SystemUI/SystemUI.apk`
- JAR files: `smali/system/framework/framework.jar`

### **customize.sh**
{: .pb-2 }
When created, this script allows to customize the patch application process. `SKIPUNZIP=1` variable can be declared if you want to skip the default patch application process (will only skip the partitions folders).

Together with all the config.sh flags, the following variables are also available in the script:
- `SRC_DIR`: path of the UN1CA root directory
- `OUT_DIR`: path of the output directory
- `TMP_DIR`: path of the temporary folder, this doesn't exists by default and can be used to temporarily store files
- `ODIN_DIR`: path of the downloaded firmwares folder
- `FW_DIR`: path of the extracted firmwares folder
- `APKTOOL_DIR`: path of the decompiled APKs/JARs folder
- `WORK_DIR`: path of the work directory
- `TOOLS_DIR`: path of the tools folder

All the tools are directly accessible without having to put the full path before (eg. `$TOOLS_DIR/bin/mkbootimg`, use `mkbootimg` only).

### **.prop files**
{: .pb-2 }
These files follows the same format as `build.prop`. Each line comprises of `[key]=[value]`. When no value is set, the prop will be removed from its destination file.
