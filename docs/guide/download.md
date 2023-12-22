---
layout: default
title: Install UN1CA (Download mode)
parent: Installation instructions
nav_order: 3
---

# Install UN1CA (Download mode)
{: .pb-2 }

{: .important }
> This guide is specific to devices in which the install method is marked as **"Download mode"**.
> If your device uses the **"Custom recovery"** install method or the file name you downloaded ends with the `.zip` extension, follow [this]({% link guide/recovery.md %}) instead.

{: .warning }
> Installing UN1CA for the first time **REQUIRES** a full data wipe (this is NOT counting the data wipe when unlocking the bootloader nor rooting your device).
> Please make a backup of your data before proceeding.

<p align="center">
  <img loading="lazy" src="/assets/images/dwnl-mode.png" width="30%"/>
</p>

Every Android OEM worthy of its name implements a proprietary "rescue mode" in its devices, useful when recovering the device from bad installs or to manually update.
While most of them rely on Google's open source [fastboot](https://android.googlesource.com/platform/system/core/+/refs/heads/main/fastboot/README.md), Samsung keeps its roots by still using their own **"Download mode"**.

To boot to Download mode, you have to power off your device and turn it on again with a specific key combo that might differ from device to device.
Samsung modern devices require you to **plug it via an USB cable to your PC** and **hold both volume up and volume down buttons** until the above screen appears on your device, then press volume up once.

In the [main section page]({% link guide/index.md %}) you can find a list of tools you can use to communicate with your device while it's in Download mode, for any platform that your PC might be running on.
To install UN1CA or other unofficial images, your device's bootloader **must be unlocked**. If you're unsure please give a look at the ["Unlocking the bootloader"]({% link guide/bootloader.md %}) page.

Once you've made sure your device's bootloader is unlocked and have downloaded/installed all the required tools in your PC, you can proceed with the following steps:

- Download the latest available UN1CA tar package for your device
- Reboot your device to Download mode: power off your device and connect it to your PC while pressing the Download mode key combo for your device.
- Depending by your platform:
  - Odin3 **(Windows)**:\
    Open Odin3, click the **"AP"** button and select the UN1CA package you previously downloaded, then click the **"Start"** button.
  - Odin4 **(Linux)**:\
    Open a terminal window pointing to the directory where you stored the odin4 executable, then run:
    ```bash
    ./odin4 -a <file>
    ```
    With `<file>` being the path to the UN1CA package you previously downloaded.
  - Heimdall **(multi-platform)**:\
    Heimdall **does not support** flashing Samsung `.tar` packages directly, you'll have to instead flash each individual image manually.
    To do so, extract the content of the UN1CA package you previously downloaded and decompress each `.lz4` image. You can do so with the following code snippet via your terminal:
    ```bash
    for i in *.lz4; do
        lz4 -d --rm "$i" "${i%.lz4}"
    done
    ```
    Once you have all the `.img` files decompressed, run `heimdall flash` via your terminal to start the flash.
    This command will be in the format of **--the name of the partition slot** followed by **the actual file path**.
    For example, this is the command you have to run if the `.tar` package you extracted contains `boot.img`, `dtbo.img`, `vendor_boot.img` and `super.img`:
    ```bash
    heimdall flash --BOOT boot.img --DTBO dtbo.img --VENDOR_BOOT vendor_boot.img --SUPER super.img
    ```

If you have followed every step correctly, the flash procedure will start and you will see a progress indicator both in your device and the tool you're using in your PC. The device will automatically reboot into the OS once the flash procedure ends.

**A factory reset is required to avoid any sort of issues when installing the ROM for the first time in your device.** If your device asks you to do a factory reset, please do so.

If you encounter any error/issue, please refer to the [Troubleshooting]({% link faq/index.md %}) section.

## Updating the ROM
{: .pb-2 }
To update the ROM, you can simply follow the same exact steps you've followed for the first time install, except for for the data wipe which is not necessary anymore.
