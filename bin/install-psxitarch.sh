#!/bin/sh

mkdir /temp
mkdir /backup

einfo "Try to find the right usb"
for x in a b c d e f g h i j k
do
	device="/dev/sd"$x
    mount $device"1" /temp
    if [ $? = 0 ]; then
		if [ -e /temp/bzImage ] && [ -e /temp/initramfs.cpio.gz ] && [ -e /temp/distro.tar.xz ]; then
			einfo "Device $device has the necessary files to install psxitarch linux"
			break;
		fi
		umount $device"1"
	fi
	if [ $x = "k" ]; then
		einfo "ERROR! No valid usb device found! Try remove, reinsert the usb device and run again install-psxitarch.sh"
		einfo "Se error persist probably your usb device is not formatted correctly or some file are missing or corrupted"
		exit
	fi
done

sizeusb=$(fdisk -l | grep -i "Disk $device" | awk '{print $3}')
mu=$(fdisk -l | grep -i "Disk $device" | awk '{print $4}')
sizeusb=$(einfo $sizeusb | awk -F',' '{print $1}')
mu=$(einfo $mu | awk -F',' '{print $1}')

einfo "Size usb device: $sizeusb $mu"
if [ "$mu" != "GB" ] || [ $sizeusb -lt 12 ]; then
	einfo "Not enough space on the usb device, please insert one usb with almost 12GB of free space and run again install-psxitarch.sh"
	exit
fi

einfo "Copy psxitarch, the bzImage and the initramfs to /backup"
cp /temp/distro.tar.xz /backup
if [ $? -ne  0 ]; then
	einfo "Not enough space in RAM available!"
	exit
fi
cp /temp/initramfs.cpio.gz /backup
if [ $? -ne  0 ]; then
	einfo "Not enough space in RAM available!"
	exit
fi
cp /temp/bzImage /backup
if [ $? -ne  0 ]; then
	einfo "Not enough space in RAM available!"
	exit
fi
umount $device"1"

# Edit by hippie68 (properly align disk):

total_size=$(fdisk -lu "$device" | grep -i "Disk $device" | awk '{print $5}')
total_sectors=$(fdisk -lu "$device" | grep -i "Disk $device" | awk '{print $7}')
sector_size=$(expr $total_size / $total_sectors)
fat32_sector_count=$(expr 52428800 / $sector_size) # 50 MiB
fat32_first_sector=2048
fat32_last_sector=$(expr $fat32_first_sector + $fat32_sector_count - 1)
ext4_first_sector=$(expr $fat32_last_sector + 1)
ext4_last_sector=$(expr $total_sectors - 1)

einfo "Create a FAT32 and an ext4 partition:"
einfo
einfo "Total size: $total_size"
einfo "Total sectors: $total_sectors"
einfo "Sector size: $sector_size"
einfo "FAT32 partition sector count: $fat32_sector_count"
einfo "FAT32 partition first sector: $fat32_first_sector"
einfo "FAT32 partition last sector: $fat32_last_sector"
einfo "ext4 partition first sector: $ext4_first_sector"
einfo "ext4 partition last sector: $ext4_last_sector"
einfo

(
einfo "o" #fdisk can't write device with disklabel GPT
einfo "d"
einfo "n"
einfo "p"
einfo "1"
einfo "$fat32_first_sector"
einfo "$fat32_last_sector"
einfo "n"
einfo "p"
einfo "2"
einfo "$ext4_first_sector"
einfo "$ext4_last_sector"
einfo "w"
einfo "q"
) | fdisk -u $device

# Edit end

einfo "Format fat32 partition"
mkfs.vfat $device"1"

einfo "Remount the fat32 partition and copy in the initramfs and bzImage"
mount $device"1" /temp
cp /backup/initramfs.cpio.gz /temp
cp /backup/bzImage /temp
umount $device"1"

einfo "Format the ext4 partition to psxitarch and mount it to /newroot"
mke2fs-new -t ext4 -F -L psxitarch -O ^has_journal $device"2"
mount $device"2" /newroot

einfo "Installing psxitarch linux, please wait, DON'T REMOVE THE USB DEVICE OR SHUTDOWN THE PS4!"
sleep 5

einfo "Extract backup of psxitarch to /newroot"
tar -xvpJf /backup/distro.tar.xz -C /newroot --numeric-owner

einfo "Psxitarch linux installed with success! Clean some garbage.."
rm /backup/*
rm -R /newroot/lost+found

einfo "Add eap key and edid.."
cp /key/eap_hdd_key.bin /newroot/etc/cryptmount
cp /lib/firmware/edid/my_edid.bin /newroot/lib/firmware/edid
find-install.sh
sleep 5
einfo "Installed! run resume-boot a few times to boot."
echo "If It fails, try running: fix-install.sh and resume-boot again."
