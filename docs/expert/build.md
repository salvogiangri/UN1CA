---
layout: default
title: Build UN1CA
parent: Developer guides
nav_order: 1
---

# Build UN1CA
{: .pb-2 }
Building UN1CA is pretty straightforward and only requires running a few commands to get the job done. However, setting up your environment correctly is necessary before proceeding to avoid errors/issues.

## Minimum requirements
{: .pb-2 }
- Linux-based OS x64 (WSL has not been tested yet)
- 16 GB+ RAM
- 40 GB+ free space

## System dependencies
{: .pb-2 }
The following dependencies must be installed:
- [brotli](https://github.com/google/brotli)
- [Ccache](https://ccache.dev/)
- [Clang](https://clang.llvm.org/)
- [Git](https://git-scm.com/)
- [Google Test](https://github.com/google/googletest)
- [Ninja](https://ninja-build.org/)
- [Node.js](https://nodejs.org/) (installing via [nvm](https://github.com/nvm-sh/nvm) is suggested)
- [protobuf](https://github.com/protocolbuffers/protobuf)
- [Python 3](https://www.python.org/) (or newer)
- [Java 11](https://www.java.com/)
- [libusb](https://libusb.info/)
- [lz4](https://github.com/lz4/lz4)
- [PCRE](https://pcre.sourceforge.net/)
- [Perl](https://www.perl.org/)
- [zip](https://www.unix.com/man-page/v7/1/zip/)
- [zipalign](https://developer.android.com/tools/zipalign)
- [zstd](https://facebook.github.io/zstd/)

For reference, here's an example on how to install most of the dependencies via APT:
```bash
sudo apt install -y \
    attr ccache clang git golang libbrotli-dev \
    libgtest-dev libprotobuf-dev libunwind-dev libusb-1.0-0-dev libzstd-dev lld \
    ninja-build openjdk-11-jdk protobuf-compiler zip zipalign
```

## Building UN1CA
{: .pb-2 }
Once you have made sure all the dependencies are installed, you can now clone the repository via git:
```bash
git clone --recurse-submodules https://github.com/BlackMesa123/UN1CA.git && cd UN1CA
```

If you have the repository cloned already, but didn't clone the submodules, you can do so afterwards with the following command:
```bash
git submodule update --init --recursive
```

It's now time to set up the build system. The following command will automatically build all the required tools by the build system and generate the build config for the choosen target device.
```bash
. ./buildenv.sh <target>
```

Now you just have to build the ROM with:
```bash
run_cmd make_rom
```

If everything went right, you'll find the generated flashable zip/tar file inside the `out` folder.

{: .highlight }
*Continue to [How the build system works]({% link expert/details.md %})*
