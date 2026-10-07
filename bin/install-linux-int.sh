#!/bin/sh
. /functions.sh
# Prompt user for seek value
eask "Enter the amount of storage to dedicate to your linux install (GB's): "
read seek_value

# Check if key file exists and is readable
if test -r /key/eap_hdd_key.bin; then
    # Check if physical device exists and is accessible
    if test -b /dev/sda27; then
        # Set up encrypted device
        cryptsetup -d /key/eap_hdd_key.bin --cipher=aes-xts-plain64 -s 256 --offset=0 --skip=111669149696 create ps4hdd /dev/sda27

        # Check if /ps4hdd directory exists
        if test -d /ps4hdd; then
            einfo "/ps4hdd directory already exists. Skipping mkdir command."
        else
            # Create directory
            mkdir /ps4hdd
        fi

        # Mount encrypted device
        mount -a -t ufs -o ufstype=ufs2 /dev/mapper/ps4hdd /ps4hdd

        # Check if mount was successful
        if mountpoint -q /ps4hdd; then
            if test -r /ps4hdd/system/boot/psxitarch.tar.xz; then
                mv -f /ps4hdd/system/boot/psxitarch.tar.xz /ps4hdd/system/boot/distro.tar.xz
                ewarn "psxitarch.tar.xz was found, but was renamed to distro.tar.xz. from now on, please use distro.tar.xz instead of psxitarch.tar.xz."
                sleep 1
            fi
            # Create image file with user-specified seek value and set up loop device
            dd if=/dev/null of=/ps4hdd/home/linux.img bs=1073741824 seek=$seek_value
            losetup /dev/loop5 /ps4hdd/home/linux.img

            # Create ext4 filesystem on loop device
            mkfs.ext4 /dev/loop5

            # Mount loop device
            mount /dev/loop5 /newroot
            # Check if mount was successful
            if mountpoint -q /newroot; then
                # Extract tar file to new root directory
                if test -r /ps4hdd/system/boot/distro.tar.xz; then
                    ( cd /newroot; tar -xvJf /ps4hdd/system/boot/distro.tar.xz; )
                    einfo "--INSTALL COMPLETE--"
                    einfo "If you are reading this message type: resume-boot a few times to boot into the distro"
                    einfo "If It fails, try running: fix-install.sh and resume-boot again."
                    find-install.sh
                else
                    eerror "Error: /ps4hdd/system/boot/distro.tar.xz file does not exist or is not readable."
                    exit 1
                fi
            else
                eerror "Error: failed to mount /dev/loop5 on /newroot."
                exit 1
            fi
        else
            eerror "Error: failed to mount /dev/mapper/ps4hdd on /ps4hdd."
            exit 1
        fi
    else
        eerror "Error: /dev/sda27 device does not exist or is not accessible."
        exit 1
    fi

    else
        eerror "Error: decryption key does not exist or is not accessible."
        exit 1
    fi
resume-boot
