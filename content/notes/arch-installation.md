---
title: "Arch installation"
date: 2021-11-13T22:19:07+01:00
draft: false
---

Steps to get up and running with Arch Linux.

<!--more-->

Boot arch iso

```
# Increase font size (optional)
# console fonts directory: /usr/share/kbd/consolefonts
setfont ter-132n

# check IP
ip a

# partition & mount
lsblk

gdisk /dev/sda

# inside gdisk create 3 partitions:
# - boot (EFI) 250M
# - swap 2GB
# - root 25GB
# - home remaining
#
# boot:
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), +250M [ENTER], ef00 [ENTER] (efi partition)
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), +2G [ENTER], 8200 [ENTER] (swap)
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), +25G [ENTER], (8300) [ENTER] (Linux filesystem)
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), [ENTER], (8300) [ENTER] (Linux filesystem)
#
# now w [ENTER] to write to disk

# check names of disks again
lsblk

# format disks
mkfs.vfat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3
mkfs.ext4 /dev/nvme0n1p4

# mount partitions
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/efi
mkdir /mnt/home
mount /dev/nvme0n1p1 /mnt/boot/efi
mount /dev/nvme0n1p4 /mnt/home

# sync repos
pacman -Sy

# base install
pacstrap /mnt base linux linux-firmware linux-headers git vim

# generate filesystem table with UUIDs of the partitions
genfstab -U /mnt >> /mnt/etc/fstab

# now enter the new installation
arch-chroot /mnt

# run install script
git clone https://gist.github.com/jeroenbourgois/ba337f0ffca32614bd740779b152ce70

# now check videodriver (nvidia)
vim /etc/mkinitcpio.conf
mkinitcpio -p linux

# edit grub
vim /etc/default/grub
# > GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet video=1920x1080"
# > GRUB_GFXMODE=1920x1080
grub-mkconfig -o /boot/grub/grub.cfg

# now exit installation and reboot
exit
umount -a
reboot

# refresh package servers
# sudo reflector -c Belgium -a 12 --sort rate --save /etc/pacman.d/mirrorlist

sudo flatpak install -y spotify

# default X config
cp /etc/X11/xinit/xinitrc ~/.xinitrc
vim ~/.xinitrc # at the bottom add 'exec i3'

# update .zshrc

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec startx
fi

```

Also see:

- https://confluence.jaytaala.com/display/TKB/My+Manjaro+i3+setup
- https://faq.i3wm.org/question/6126/how-do-i-start-i3/index.html
