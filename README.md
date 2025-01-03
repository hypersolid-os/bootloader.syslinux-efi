hypersolid syslinux efi bootloader for baremetal systems
===================================================================

**boot hypersolid via syslinux efi**

Use [syslinux/syslinux](https://wiki.syslinux.org/wiki/index.php?title=syslinux) as bootloader to load hypersolid.


Features
===================

* efi mode
* pre-build partition kayout
* dual system partitions (primary and backup)
* variable system partition size

How to deploy
===================

Write the image directly to the device via `dd`

```bash
# extract image and write to disk
gzip -d -c boot.img.gz | dd bs=4M status=progress of=/dev/sdX

# create new uuid's and rewrite secondary GPT table to the end of the disk
sgdisk -G /dev/sdX && sync
```

hypersolid partition layout
=================================

The following GPT based partition layout is recommended but not required (of course, syslinux can handle ext2 on gpt including legacy/mbr mode).

* Partition 1 "efiboot"  - `200+XMB` | `FAT32` | syslinux efi loader ons esp partition including kernel+initramfs(1)
* Partition 2 "conf"     - `512MB` | `EXT4`  | hypersolid persistent storage
* Partition 3 "system0"  - `YGB`   | `EXT4`  | hypersolid system0 partition including `system.img`
* Partition 4 "system1"  - `YGB`   | `EXT4`  | hypersolid system1 partition including `system.img`


**Optional partitions**

* Partition 5 "swap"     - `4GB`   | `EXT4`  | swap (optional)
* Partition 6 "data"     - `XGB`   | `EXT4`  | persistent storage (optional)

Build the image
===================

This bootloader-generator creates a raw GPT disk image with 4 paritions (boot, config) including all required bootloader files + configs. The build environment is isolated within a docker container but requires full system access (privileged mode) due to the use of loop devices.

Just run `build.sh` to build the docker image and trigger the image build script. The disk image will be copied into the `dist/` directory.

**basic build**

```bash
# ./build.sh [SYS_PART_SIZE] [layout]

# e.g. 2x 5GB system partitions
./build.sh 5000
```

**with ui + rescue**

```bash
# ./build.sh [SYS_PART_SIZE] [layout]

# e.g. 2x 3GB system partitions + syslinux spalsh screen + addiitonal 500M partition1 space for rescue images 
./build.sh 3000 ui
```

Custom Splash
===================

```bash
# size 1024x768
convert -depth 16 -colors 256 syslinux.png splash.png
```

License
----------------------------

**hypersolid** is OpenSource and licensed under the Terms of [GNU General Public Licence v2](LICENSE.txt). You're welcome to [contribute](CONTRIBUTE.md)!