#!/bin/sh
. /functions.sh
umount /newroot 2>/dev/null;
if mount LABEL=psxitarch /newroot 2>/dev/null; then
    einfo "Mounted external installation."
else
    ewarn "External installation not found, checking internal drive..."

    # Internal Setup

    if mount /ps4hdd/home/linux.img /newroot 2>/dev/null; then
        einfo "Mounted internal installation."
    else
        ewarn "No installation found on internal drive either."
    fi
fi
