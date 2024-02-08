---
layout: default
title: Galaxy S21 FE 5G (Qualcomm)
parent: Supported devices
---

<p align="center">
  <img loading="lazy" src="/assets/images/s21fe.png"/>
</p>

# Galaxy S21 FE 5G (Qualcomm)
{: .pb-4 }
- Maintainer: [@glikched](https://github.com/glikched)
- Latest version: ![img](https://img.shields.io/github/v/release/BlackMesa123/UN1CA?filter=r9q-*&style=flat-square&color=89bcff) ![img](https://img.shields.io/github/v/release/BlackMesa123/UN1CA?filter=r9q2*&style=flat-square&color=89bcff)
- Install method: [Custom recovery]({% link guide/recovery.md %})
- Requirements: **Android 14 bootloader**

## Support links

- [XDA Forums](https://xdaforums.com/f/samsung-galaxy-s21-fe.12389/)

## Device specifications

| Feature                        | Specification                                                                    |
| -----------------------------: | :------------------------------------------------------------------------------- |
| Chipset                        | Qualcomm SM8350 Snapdragon 888 5G                                                |
| CPU                            | Octa-core (1x2.84 GHz Cortex-X1 & 3x2.42 GHz Cortex-A78 & 4x1.80 GHz Cortex-A55) |
| GPU                            | Qualcomm Adreno 660                                                              |
| Memory                         | 6GB / 8GB RAM (LPDDR4X)                                                          |
| Shipped OS                     | Android 12 (One UI 4.0)                                                          |
| Storage                        | 128GB / 256GB (UFS 2.1)                                                          |
| SIM                            | Single SIM (Nano-SIM) or Dual SIM (Nano-SIM, dual stand-by)                      |
| Battery                        | 4500mAh Li-Ion (non-removable), 25W fast charge                                  |
| Dimensions                     | 155.7 x 74.5 x 7.9 mm (6.13 x 2.93 x 0.31 in)                                    |
| Display                        | 6.4", 1080 x 2340 pixels, 19.5:9 ratio, Super AMOLED, 120Hz (~403 ppi density)   |
| Rear Camera 1 (IMX555/S5K2LD)  | 12 MP, f/1.8, 26mm (wide), 1/1.76", 1.8µm, Dual Pixel PDAF, OIS                  |
| Rear Camera 2 (IMX258/HI1336C) | 12 MP, f/2.2, 13mm, 123˚ (ultrawide), 1/3.0", 1.12µm                             |
| Rear Camera 3 (HI847)          | 8 MP, f/2.4, 76mm (telephoto), 1/4.5", 1.0µm, PDAF, OIS, 3x optical zoom         |
| Front Camera (IMX616)          | 32 MP, f/2.2, 26mm (wide), 1/2.74", 0.8µm                                        |
| Fingerprint                    | Goodix GW9558 (under display, optical)                                           |
| Sensors                        | Accelerometer, Gyro, Proximity (virtual), Compass, Hall IC, Grip                 |
| Extras                         | Dual speakers, NFC                                                               |

## How to build

```bash
git clone --recurse-submodules https://github.com/BlackMesa123/UN1CA.git && cd UN1CA
. ./buildenv.sh r9q
run_cmd make_rom
run_cmd cleanup apktool work_dir
. ./buildenv.sh r9q2
run_cmd make_rom
```
