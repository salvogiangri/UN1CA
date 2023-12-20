---
layout: default
title: Unlocking the bootloader
parent: Installation instructions
nav_order: 1
---

# Unlocking the bootloader
{: .pb-2 }
<p align="center">
  <img loading="lazy" src="/assets/images/dev-options.jpg" width="30%"/>
  <img loading="lazy" src="/assets/images/bl-unlock.png" width="30%"/>
</p>

Unlocking your bootloader is a fundamental step when customizing your device, as this allows you to flash and install unofficial images in it. Please note this procedure **will completely wipe your data**, so make a backup before proceeding.
To check if your bootloader is already unlocked, boot your device in Download mode with its key combo and check the OEM Lock status.

Possible OEM Lock values are the following:
- **ON (L)**: fully locked.
- **ON (U)**: bootloader locked, OEM unlocking enabled.
- **OFF (U)**: fully unlocked.

To unlock your bootloader, follow the instructions below. If no OEM Lock value is shown in Download mode, your device is probably not unlockable due to market limitations (USA/Canada devices).

KnoxGuard status should also be checked to ensure your device hasn't been locked by your carrier or Samsung itself.

Possible KnoxGuard values are the following:

- `Active`, `Locked`: your device has been remotely locked by your telecom operator or your insurance company.
- `Prenormal`: your device is temporarily locked, reaching 168h of uptime should trigger unlock.
- `Checking`, `Completed`, `Broken`: your device is unlocked.

Having KnoxGuard active will prevent you from installing/running unofficial images regardless of your bootloader lock state.

## Unlocking the bootloader
{: .pb-1 }
- Open the Settings app, enter Developer Options and enable OEM unlocking (If you don't see Developer Options, enter into About phone → Software info and tap "Build number" 10 times to show it).
- Reboot to download mode: power off your device and press the download mode key combo for your device.
- Long press volume up to unlock the bootloader. **This will wipe your data and automatically reboot.**
- Go through the initial setup. Skip through all the steps since data will be wiped again in later steps. **Connect the device to Internet during the setup.**
- Enable Developer Options, and **confirm that the OEM unlocking option exists and is grayed out.** This means KnoxGuard hasn't locked your device.

<p align="center">
  <img loading="lazy" src="/assets/images/avb-orange.png" width="30%"/>
</p>

If everything went right, your device will start to display the above warning at every boot, this cannot be removed in any way (if not by locking again your bootloader) as it's mandatory on any Android device (source: [Google](https://source.android.com/docs/security/features/verifiedboot/boot-flow#unlocked-devices)).

## Locking the bootloader
{: .pb-1 }
If you'll ever feel like locking back your bootloader, you can do so by following the unlock instructions on reverse: boot in Download mode, lock your bootloader by holding volume up, disable OEM unlocking toggle in Developer Options.

Please note that:
- This will again completely wipe your data.
- The device must have already installed the full stock untouched firmware, otherwise issues might happen when locking back your bootloader.
- Your Knox Warranty Bit will not be restored by locking back your bootloader, a solution such as [KnoxPatch](https://github.com/BlackMesa123/KnoxPatch) is suggested if you intend to stay on the stock firmware.
