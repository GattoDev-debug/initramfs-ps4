#!/bin/sh

mount LABEL=psxitarch /newroot

echo "Booting psxitarch linux, please wait.." 
exec switch_root /newroot /newroot/sbin/init &
sleep 2 &&
exec switch_root /newroot /newroot/sbin/init &
sleep 2 &&
exec switch_root /newroot /newroot/sbin/init
