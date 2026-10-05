#!/bin/sh

. /functions.sh
if mountpoint -q /newroot; then
    einfo "Creating folders on /newroot..."
    mkdir -p /newroot/dev
    mkdir -p /newroot/media
    mkdir -p /newroot/mnt
    mkdir -p /newroot/proc
    mkdir -p /newroot/run
    mkdir -p /newroot/sys
    mkdir -p /newroot/tmp
    mkdir -p /newroot/var/cache
    mkdir -p /newroot/var/log
    mkdir -p /newroot/var/tmp
    einfo "Done!"
else
    eerror "/newroot is not a mountpoint, please reboot."
fi
