#!/bin/sh

. /functions.sh

TEMP_DIR="/temp"
BACKUP_DIR="/backup"
NEWROOT="/newroot"

mkdir -p "$TEMP_DIR"
mkdir -p "$BACKUP_DIR"


einfo "Searching for the correct USB device..."

device=""

for letter in a b c d e f g h i j k
do
    current_device="/dev/sd$letter"

    mount "${current_device}1" "$TEMP_DIR" 2>/dev/null

    if [ $? -eq 0 ]; then
        if [ -f "$TEMP_DIR/bzImage" ] &&
           [ -f "$TEMP_DIR/initramfs.cpio.gz" ] &&
           [ -f "$TEMP_DIR/distro.tar.xz" ]; then

            device="$current_device"

            einfo "Found installation USB: $device"

            break
        fi

        umount "${current_device}1"
    fi
done


if [ -z "$device" ]; then
    einfo "ERROR! No valid USB device found!"
    einfo "Remove and reinsert the USB device, then run the script again."
    einfo "If the error persists, the USB may be incorrectly formatted or missing required files."
    einfo "...Or you know, I wrote this script wrong."
    exit 1
fi


sizeusb=$(fdisk -l "$device" | grep -i "Disk $device" | awk '{print $3}')
mu=$(fdisk -l "$device" | grep -i "Disk $device" | awk '{print $4}')

sizeusb=$(einfo "$sizeusb" | awk -F',' '{print $1}')
mu=$(einfo "$mu" | awk -F',' '{print $1}')

einfo "USB device size: $sizeusb $mu"


einfo "Copying installation files to RAM..."

cp "$TEMP_DIR/distro.tar.xz" "$BACKUP_DIR/"

if [ $? -ne 0 ]; then
    eerror "ERROR! Not enough RAM available."
    exit 1
fi

cp "$TEMP_DIR/initramfs.cpio.gz" "$BACKUP_DIR/"

if [ $? -ne 0 ]; then
    eerror "ERROR! Not enough RAM available."
    exit 1
fi

cp "$TEMP_DIR/bzImage" "$BACKUP_DIR/"

if [ $? -ne 0 ]; then
    eerror "ERROR! Not enough RAM available."
    exit 1
fi

umount "${device}1"


total_size=$(fdisk -lu "$device" | grep -i "Disk $device" | awk '{print $5}')
total_sectors=$(fdisk -lu "$device" | grep -i "Disk $device" | awk '{print $7}')

sector_size=$(expr "$total_size" / "$total_sectors")

fat32_sector_count=$(expr 52428800 / "$sector_size")

fat32_first_sector=2048
fat32_last_sector=$(expr "$fat32_first_sector" + "$fat32_sector_count" - 1)

ext4_first_sector=$(expr "$fat32_last_sector" + 1)
ext4_last_sector=$(expr "$total_sectors" - 1)


einfo "Preparing USB partition layout..."
einfo
einfo "Device: $device"
einfo "Total size: $total_size"
einfo "Total sectors: $total_sectors"
einfo "Sector size: $sector_size"
einfo "FAT32 first sector: $fat32_first_sector"
einfo "FAT32 last sector: $fat32_last_sector"
einfo "ext4 first sector: $ext4_first_sector"
einfo "ext4 last sector: $ext4_last_sector"
einfo


(
    einfo "o"
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
) | fdisk -u "$device"


einfo "Formatting FAT32 partition..."

mkfs.vfat "${device}1"


einfo "Copying boot files to FAT32 partition..."

mount "${device}1" "$TEMP_DIR"

cp "$BACKUP_DIR/initramfs.cpio.gz" "$TEMP_DIR/"
cp "$BACKUP_DIR/bzImage" "$TEMP_DIR/"

umount "${device}1"


einfo "Formatting ext4 partition..."

mke2fs-new \
    -t ext4 \
    -F \
    -L psxitarch \
    -O ^has_journal \
    "${device}2"

mount "${device}2" "$NEWROOT"


einfo "Installing Linux..."
einfo "DO NOT REMOVE THE USB DEVICE OR SHUT DOWN THE PS4!"

sleep 5


einfo "Extracting Linux..."

tar \
    -xvpJf "$BACKUP_DIR/distro.tar.xz" \
    -C "$NEWROOT" \
    --numeric-owner


einfo "Installation completed successfully."
einfo "Cleaning temporary files..."

rm -f "$BACKUP_DIR"/*

rm -rf "$NEWROOT/lost+found"


einfo "Installing EAP key and EDID..."

cp \
    /key/eap_hdd_key.bin \
    "$NEWROOT/etc/cryptmount"

cp \
    /lib/firmware/edid/my_edid.bin \
    "$NEWROOT/lib/firmware/edid"


find-install.sh

sleep 5


einfo "Linux installed!"
einfo "Run resume-boot a few times to boot."
einfo "If it fails, run fix-install.sh and then resume-boot again."
