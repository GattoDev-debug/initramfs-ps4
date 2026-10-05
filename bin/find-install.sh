#!/bin/sh
. /functions.sh
if mount LABEL=psxitarch /newroot 2>/dev/null; then
    einfo "Mounted external installation."
else
    ewarn "External installation not found, checking internal drive..."

    # Internal Setup
    cryptsetup -d /key/eap_hdd_key.bin --cipher aes-xts-plain64 -s 256 --offset 0 --skip 111669149696 create ps4hdd /dev/sd?27
    mkdir -p /ps4hdd
    mount -t ufs -o ufstype=ufs2 /dev/mapper/ps4hdd /ps4hdd

    if mount /ps4hdd/home/linux.img /newroot 2>/dev/null; then
        einfo "Mounted internal installation."
    else
        ewarn "No installation found on internal drive either."
    fi
fi
