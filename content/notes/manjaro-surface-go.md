---
title: "Manjaro on my Surface Go"
date: 2019-12-20T22:19:07+01:00
draft: false
---

# Install and run Manjaro on a Microsoft Surface Go

This mostly just contains personal notes and references to get the Manjaro i3 flavor running.

This largely follows the steps in my 'Manjaro on a MBP' {{< ref "/notes/manjaro-mbp" >}} post, only the differences are highlighted here.

## Prepare

Because I could not get the bootloader menu to work properly and I did not need Windows at all, I decided to erase it all together and just do a clean install of Manjaro.
To do so, like on the MBP, I just used the live usb to do the installation.

## Post install

To get most of the things working, use the
https://www.reddit.com/r/SurfaceLinux/comments/94hjxv/surface_go_first_impressions/

## Issues

### Wifi

Thanks to the *wonderfull* `linux-surface` repo, you can fix the WiFi and other minor issues:

- download / clone the (repo)[https://github.com/jakeday/linux-surface] to a usb disk
- copy the files to your surface
- run `sudo sh setup.sh`
- reboot

Just recently, afer a big `sudo pacman -Syu` operation, I had to run this again. For convenience, keep the files around somewhere in you home directory.
