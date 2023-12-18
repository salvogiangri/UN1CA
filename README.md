<h3 align="center">:warning: W.I.P.</h3>
<h1 align="center">
  <img loading="lazy" src="readme-res/banner.png"/>
</h1>
<p align="center">
  <a href="https://github.com/BlackMesa123/UN1CA/blob/fourteen/LICENSE"><img loading="lazy" src="https://img.shields.io/github/license/BlackMesa123/UN1CA?style=for-the-badge&logo=github"/></a>
  <a href="https://github.com/BlackMesa123/UN1CA/releases/latest"><img loading="lazy" src="https://img.shields.io/github/v/release/BlackMesa123/UN1CA?style=for-the-badge"/></a>
  <a href="https://github.com/BlackMesa123/UN1CA/commits/fourteen"><img loading="lazy" src="https://img.shields.io/github/last-commit/BlackMesa123/UN1CA/fourteen?style=for-the-badge"/></a>
  <a href="https://github.com/BlackMesa123/UN1CA/stargazers"><img loading="lazy" src="https://img.shields.io/github/stars/BlackMesa123/UN1CA?style=for-the-badge"/></a>
  <a href="https://github.com/BlackMesa123/UN1CA/graphs/contributors"><img loading="lazy" src="https://img.shields.io/github/contributors/BlackMesa123/UN1CA?style=for-the-badge"/></a>
  <a href="https://github.com/BlackMesa123/UN1CA/actions"><img loading="lazy" src="https://img.shields.io/github/actions/workflow/status/BlackMesa123/UN1CA/build.yml?style=for-the-badge"/></a>
</p>
<p align="center">UN1CA <i>(/ˈu.ni.ka/)</i> is a work-in-progress custom firmware for Samsung Galaxy devices.</p>

# How to build
```bash
git clone --recurse-submodules https://github.com/BlackMesa123/UN1CA.git && cd UN1CA
. ./buildenv.sh <device>
run_cmd download_fw
run_cmd make_rom
```

# Licensing

This project is licensed under the terms of the [GNU General Public License v3.0](LICENSE). External dependencies might be released under a different license, such as:
- [android-tools](https://github.com/nmeum/android-tools), licensed under the [Apache License 2.0](https://github.com/nmeum/android-tools/blob/master/LICENSE)
- [apktool](https://github.com/iBotPeaches/Apktool), licensed under the [Apache License 2.0](https://github.com/iBotPeaches/Apktool/blob/master/LICENSE.md)
- [erofs-utils](https://github.com/sekaiacg/erofs-utils/), dual license ([GPL-2.0](https://github.com/sekaiacg/erofs-utils/blob/dev/LICENSES/GPL-2.0), [Apache-2.0](https://github.com/sekaiacg/erofs-utils/blob/dev/LICENSES/Apache-2.0))
- [img2sdat](https://github.com/xpirt/img2sdat), licensed under the [MIT License](https://github.com/xpirt/img2sdat/blob/master/LICENSE)
- [platform_build](https://android.googlesource.com/platform/build/) (ext4_utils, f2fs_utils, signapk), licensed under the [Apache License 2.0](https://source.android.com/docs/setup/about/licenses)

# Stargazers over time
[![Stargazers over time](https://starchart.cc/BlackMesa123/UN1CA.svg)](https://starchart.cc/BlackMesa123/UN1CA)
