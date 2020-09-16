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

# Create sparse file to represent our disk
truncate --size 8712M $VIRTUAL_DISK

# Create partition layout
sgdisk --clear \
  --new 1::+200M  --typecode=1:ef00 --change-name=1:'efiboot' \
  --new 2::+2G    --typecode=2:8300 --change-name=2:'system0' \
  --new 3::+2G    --typecode=2:8300 --change-name=3:'system1' \
  --new 4::+512M  --typecode=3:8300 --change-name=4:'conf' \
  --new 5::-0M    --typecode=4:8200 --change-name=5:'swap' \
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
mkswap    ${LOOPDEV}p5

# EFI
# ---------------------------

# mount efi partition
mount ${LOOPDEV}p1 /mnt/esp

# create syslinux dir
mkdir -p /mnt/esp/efi/boot

# copy efi loader
cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /mnt/esp/efi/boot/bootx64.efi
cp /usr/lib/syslinux/modules/efi64/ldlinux.e64 /mnt/esp/efi/boot/

# copy config files
cp /opt/conf/syslinux.efi.cfg /mnt/esp/efi/boot/syslinux.cfg

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
cp ${VIRTUAL_DISK}.gz /tmp/dist/