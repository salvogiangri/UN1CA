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
├── out                 <--- Output folder
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

### **buildenv.sh**
{: .pb-2 }
This script will automatically set up your current shell instance to build UN1CA, by adding the `run_cmd` function. Usage of this script is:
```bash
. ./buildenv.sh <target>
```
With `<target>` being the device name. A list of all the available devices can be seen by running the command without any argument.
