#!/bin/sh
. /functions.sh
missing_amdgpu=0
missing_mrvl=0

if ! [ -d /lib/firmware/amdgpu ] || ! find /lib/firmware/amdgpu -type f -print -quit 2>/dev/null | grep -q .; then
	missing_amdgpu=1
fi

if ! [ -d /lib/firmware/mrvl ] || ! find /lib/firmware/mrvl -type f -print -quit 2>/dev/null | grep -q .; then
	missing_mrvl=1
fi

if [ "$missing_amdgpu" -eq 1 ] && [ "$missing_mrvl" -eq 1 ]; then
	eerror "You are missing firmware. (2/2)"
elif [ "$missing_amdgpu" -eq 1 ]; then
	eerror "You are missing liverpool firmware. (1/2)"
elif [ "$missing_mrvl" -eq 1 ]; then
	eerror "You are missing Marvell firmware. (1/2)"
fi
