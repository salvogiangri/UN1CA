# img2sdat
Convert filesystem ext4 image (.img) into Android sparse data image (.dat)



## Requirements
This binary requires Python 2.7 or newer installed on your system.

It currently supports Windows x86/x64, Linux x86/x64 & arm/arm64 architectures.



## Usage
```
img2sdat.py <system_img> [-o outdir] [-v version] [-p prefix]
```
- `<system_img>` = input system image
- `[-o outdir]` = output directory (current directory by default)
- `[-v version]` = transfer list version number (1 - 5.0, 2 - 5.1, 3 - 6.0, 4 - 7.0, will be asked by default, more info on xda thread)
- `[-p prefix]` = name of image (prefix.new.dat)



## Example
This is a simple example on a Linux system:
```
~$ ./img2sdat.py system.img -o tmp -v 4
```
It will create files `system.new.dat`, `system.patch.dat`, `system.transfer.list` in directory `tmp`.



## Info
For more information about this binary, visit http://forum.xda-developers.com/android/software-hacking/how-to-conver-lollipop-dat-files-to-t2978952.
