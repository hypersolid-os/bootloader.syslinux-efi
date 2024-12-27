#!/usr/bin/env bash

# apt-get install qemu-system-x86 ovmf
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host -smp cores=4,threads=1 -m 4096 \
    -vga qxl \
    -net none \
    -machine q35,smm=on \
    -smbios type=0,uefi=on --bios /usr/share/qemu/OVMF.fd \
    -drive format=raw,file=dist/syslinux-efi.img