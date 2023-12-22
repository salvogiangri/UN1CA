---
layout: default
title: Available commands
parent: Developer guides
nav_order: 3
---

# Available commands
{: .pb-2 }

In this section you'll find all the build system commands available via `run_cmd` and their usage.

## apktool
{: .pb-2 }
```bash
run_cmd apktool d[ecode]/b[uild] <file/dir> (<file/dir>...)
```

This command handles APKs/JARs decoding/building, which is controlled by the very first supplied argument:
- `d`/`decode`: decodes the input APK/JAR file(s)
- `b`/`build`: builds the input APK/JAR dir(s)

Decoded APK/JAR files will be stored in `APKTOOL_DIR` (out/apktool), each in its respective original system path, while the built APK/JAR files will be copied back to their original path.

The input APK/JAR files/folders **must match** the path in their respective system partition. Here there are some examples:
```bash
run_cmd apktool d SystemUI.apk # no
run_cmd apktool d $WORK_DIR/system/system/system_ext/priv-app/SystemUI/SystemUI.apk # no
run_cmd apktool d /system_ext/priv-app/SystemUI/SystemUI.apk # yes
run_cmd apktool b $APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk # no
run_cmd apktool b /system_ext/priv-app/SystemUI/SystemUI.apk # yes
```

## build_dependencies
{: .pb-2 }
```bash
run_cmd build_dependencies
```

This command will build all the tools required by the build system and copy them in `TOOLS_DIR` (out/tools), it is automatically ran when sourcing `buildenv.sh`.
`TOOLS_DIR` folder is also added in your `PATH` env variable, which means any built tool can be ran from your shell instance autonomously.
If you need to update or rebuild your tools, clean the tools folder first with `run_cmd cleanup tools`, as `build_dependencies` will only attempt to build the missing executables.

## build_fs_image
{: .pb-2 }
```bash
run_cmd build_fs_image <fs> <dir> <file_context> <fs_config>
```

This command will build a `.img` system image with the desidered file system. The following arguments must be supplied:
- `fs`: the output image file system, either `ext4`, `f2fs` or `erofs`. Sparse images can be built by adding "+sparse" at the end (eg. `ext4+sparse`)
- `dir`: the directory containing the partition files
- `file_context`: path to the file_context config file
- `fs_config`: path to the fs_config config file

The output image will be saved in the parent directory of the partition dir one (dir/..).

## cleanup
{: .pb-2 }
```bash
run_cmd cleanup <type> (<type>...)
```

This command will clean the desidered directory to free up space or start a fresh build. The following arguments are accepted (you can supply multiple at once):
- `all`: will delete `OUT_DIR` (the whole out directory), highly unsuggested
- `odin` will delete `ODIN_DIR` (downloaded firmwares folder)
- `fw` will delete `FW_DIR` (extracted firmwares folder)
- `apktool` will delete `APKTOOL_DIR` (decompiled APKs/JARs folder)
- `work_dir` will delete `WORK_DIR` (work directory)
- `tools` will delete `TOOLS_DIR` (tools folder)

The command `run_cmd cleanup apktool work_dir` is enough to run a fresh build.

## download_fw
{: .pb-2 }
```bash
run_cmd download_fw
```

This command will download all the firmwares required by the generated build config, more specifically the ones set in the `SOURCE_FIRMWARE`, `SOURCE_EXTRA_FIRMWARES`, `TARGET_FIRMWARE` and `TARGET_EXTRA_FIRMWARES` flags.
It also keep track of the currently downloaded firmware builds and will warn the user when a new one is available for download.

## extract_fw
{: .pb-2 }
```bash
run_cmd extract_fw
```

This command will extract all the firmwares required by the generated build config, more specifically the ones set in the `SOURCE_FIRMWARE`, `SOURCE_EXTRA_FIRMWARES`, `TARGET_FIRMWARE` and `TARGET_EXTRA_FIRMWARES` flags.
It also keep track of the currently downloaded firmware builds and will warn the user when a new one is available to extract.

## make_rom
{: .pb-2 }
```bash
run_cmd make_rom (-f/--force) (--no-rom-zip) (--no-rom-tar)
```

This command will start a new ROM build and generate a flashable zip/tar package. It will show an error when changes have happened in the repo or in the generated build config to avoid issues with dirty builds.
The following additional flags are also available:
- `-f/--force`: force the build steps regardless if there's nothing to do in the work directory
- `--no-rom-zip`: disable generating a flashable zip at the end of the build, ignored if `TARGET_INSTALL_METHOD` is set to `odin`
- `--no-rom-tar`: disable generating a flashable tar at the end of the build, ignored if `TARGET_INSTALL_METHOD` is set to `zip`

## print_modules_info
{: .pb-2 }
```bash
run_cmd print_modules_info
```

This command will print out all the packages and patches that will be processed by the build system for the selected target device.

## unsign_bin
{: .pb-2 }
```bash
run_cmd unsign_bin <image> (<image>...)
```

This command will strip off the [AVB footer](https://android.googlesource.com/platform/external/avb/+/master/README.md#the-vbmeta-struct) and/or Samsung signature from the supplied image files, useful to avoid bumping the target device's rollback prevention bit.
**Do not supply bootloader images** as flashing those might hard brick your device.

{: .highlight }
*Continue to [Build flags]({% link expert/flags.md %})*
