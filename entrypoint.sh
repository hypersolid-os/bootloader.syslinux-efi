#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0

# Fail on Error !
set -e

export VIRTUAL_DISK=/tmp/disk.img

# container build ready - attach to interactive bash
if [ -f "/.buildready" ]; then
    # just start bash
    /bin/bash
    exit 0
else
    touch /.buildready
fi

# create mount point
mkdir -p /mnt/esp

PART_BOOT_SIZE="200"
if [ "${PART_LAYOUT}" == "ui" ]; then
    echo "using UI part layout with rescue image"
    PART_BOOT_SIZE="550"
fi

# Create sparse file to represent our disk
truncate --size "$((550+${PART_BOOT_SIZE}+${PART_SYS_SIZE}*2))M" $VIRTUAL_DISK

# Create partition layout
sgdisk --clear \
  --new 1::+${PART_BOOT_SIZE}M   --typecode=1:ef00 --change-name=1:'efiboot' \
  --new 2::+512M                 --typecode=2:8300 --change-name=2:'conf' \
  --new 3::+${PART_SYS_SIZE}M    --typecode=3:8300 --change-name=3:'system0' \
  --new 4::+${PART_SYS_SIZE}M    --typecode=4:8300 --change-name=4:'system1' \
  ${VIRTUAL_DISK}

# show layout
gdisk -l ${VIRTUAL_DISK}

# mount disk
LOOPDEV=$(losetup --find --show --partscan ${VIRTUAL_DISK})

# create filesystems
mkfs.vfat -F32 ${LOOPDEV}p1
mkfs.ext4 ${LOOPDEV}p2
mkfs.ext4 ${LOOPDEV}p3
mkfs.ext4 ${LOOPDEV}p4

# EFI
# ---------------------------

# mount efi partition
mount ${LOOPDEV}p1 /mnt/esp

# create syslinux dir
mkdir -p /mnt/esp/efi/boot

# create systemd dirs
mkdir /mnt/esp/sys0
mkdir /mnt/esp/sys1
mkdir /mnt/esp/rescue

# copy efi loader
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /mnt/esp/efi/boot/bootx64.efi
cp /usr/lib/syslinux/modules/efi64/ldlinux.e64 /mnt/esp/efi/boot/

if [ "${PART_LAYOUT}" == "ui" ]; then
    echo "UI mode - adding vesamenu+splash"
    # copy menu modules
    # deps: https://wiki.syslinux.org/wiki/index.php?title=Library_modules#Syslinux_modules_working_dependencies
    cp /usr/lib/syslinux/modules/efi64/{vesamenu.c32,libutil.c32,libcom32.c32} /mnt/esp/efi/boot/

    # copy config files
    cp /opt/conf/syslinux-ui.efi.cfg /mnt/esp/efi/boot/syslinux.cfg
    cp /opt/conf/splash.png /mnt/esp/efi/boot/splash.png
else
    # copy config files
    cp /opt/conf/syslinux.efi.cfg /mnt/esp/efi/boot/syslinux.cfg
fi

# show files
tree /mnt/esp

# unmount
sync && umount /mnt/esp

# Finish
# ---------------------------

# detach loop device
losetup --detach $LOOPDEV

# compress image
gzip ${VIRTUAL_DISK}
cp ${VIRTUAL_DISK}.gz /tmp/dist/syslinux-efi-${PART_SYS_SIZE}M-sys.img.gz

# development - to use directly with qemu
#cp ${VIRTUAL_DISK} /tmp/dist/syslinux-efi.img