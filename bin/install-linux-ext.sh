#!/bin/sh

. /functions.sh
eerror "Error: This script is not functional, Please wait for an update."
exit 1
TEMP_DIR="/temp"

NEWROOT="/newroot"

mkdir -p "$TEMP_DIR"



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
    einfo "No USB device was automatically detected."
    einfo
    einfo "Available drives:"
    einfo

    number=1

    for current_device in /dev/sd[a-z]
    do
        [ -b "$current_device" ] || continue

        model=$(cat "/sys/block/${current_device#/dev/}/device/model" 2>/dev/null)
        size=$(fdisk -l "$current_device" 2>/dev/null | grep -i "Disk $current_device" | awk '{print $3,$4}')

        [ -z "$model" ] && model="Unknown"

        echo "$number - $current_device \"$model\" $size"

        number=$(expr "$number" + 1)
    done

    einfo
    printf "Pick the installation source drive: "
    read selection

    number=1

    for current_device in /dev/sd[a-z]
    do
        [ -b "$current_device" ] || continue

        if [ "$number" = "$selection" ]; then
            device="$current_device"
            break
        fi

        number=$(expr "$number" + 1)
    done

    if [ -z "$device" ]; then
        eerror "ERROR! Invalid drive selection."
        exit 1
    fi

    mount "${device}1" "$TEMP_DIR"

    if [ $? -ne 0 ]; then
        eerror "ERROR! Could not mount the selected drive."
        exit 1
    fi

    if [ ! -f "$TEMP_DIR/bzImage" ] ||
       [ ! -f "$TEMP_DIR/initramfs.cpio.gz" ] ||
       [ ! -f "$TEMP_DIR/distro.tar.xz" ]; then

        eerror "ERROR! The selected drive does not contain the required files."
        exit 1
    fi
fi


sizeusb=$(fdisk -l "$device" | grep -i "Disk $device" | awk '{print $3}')
mu=$(fdisk -l "$device" | grep -i "Disk $device" | awk '{print $4}')

sizeusb=$(einfo "$sizeusb" | awk -F',' '{print $1}')
mu=$(einfo "$mu" | awk -F',' '{print $1}')

einfo "USB device size: $sizeusb $mu"


einfo "Select the drive to install Linux onto..."
einfo
einfo "Available drives:"
einfo

number=1

for current_device in /dev/sd[a-z]
do
    [ -b "$current_device" ] || continue

    if [ "$current_device" = "$device" ]; then
        continue
    fi

    model=$(cat "/sys/block/${current_device#/dev/}/device/model" 2>/dev/null)
    size=$(fdisk -l "$current_device" 2>/dev/null | grep -i "Disk $current_device" | awk '{print $3,$4}')

    [ -z "$model" ] && model="Unknown"

    echo "$number - $current_device \"$model\" $size"

    number=$(expr "$number" + 1)
done

einfo
printf "Pick the installation drive: "
read selection


install_device=""

number=1

for current_device in /dev/sd[a-z]
do
    [ -b "$current_device" ] || continue

    if [ "$current_device" = "$device" ]; then
        continue
    fi

    if [ "$number" = "$selection" ]; then
        install_device="$current_device"
        break
    fi

    number=$(expr "$number" + 1)
done


if [ -z "$install_device" ]; then
    eerror "ERROR! Invalid drive selection."
    exit 1
fi


einfo "Installing to: $install_device"


umount "${device}1"


total_size=$(fdisk -lu "$install_device" | grep -i "Disk $install_device" | awk '{print $5}')
total_sectors=$(fdisk -lu "$install_device" | grep -i "Disk $install_device" | awk '{print $7}')

sector_size=$(expr "$total_size" / "$total_sectors")

fat32_sector_count=$(expr 52428800 / "$sector_size")

fat32_first_sector=2048
fat32_last_sector=$(expr "$fat32_first_sector" + "$fat32_sector_count" - 1)

ext4_first_sector=$(expr "$fat32_last_sector" + 1)
ext4_last_sector=$(expr "$total_sectors" - 1)


einfo "Preparing USB partition layout..."
einfo
einfo "Device: $install_device"
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
) | fdisk -u "$install_device"


einfo "Format fat32 partition"

mkfs.vfat "${install_device}1"


einfo "Copy boot files from source USB..."

mount "${install_device}1" "$NEWROOT"

cp "$TEMP_DIR/initramfs.cpio.gz" "$NEWROOT/"
cp "$TEMP_DIR/bzImage" "$NEWROOT/"

umount "${install_device}1"


einfo "Format the ext4 partition to psxitarch and mount it to /newroot"

mke2fs-new \
    -t ext4 \
    -F \
    -L psxitarch \
    -O ^has_journal \
    "${install_device}2"

mount "${install_device}2" "$NEWROOT"


einfo "Installing Linux..."
einfo "DO NOT REMOVE THE SOURCE USB DEVICE OR SHUT DOWN THE PS4!"

sleep 5


einfo "Extracting Linux..."

tar \
    -xvpJf "$TEMP_DIR/distro.tar.xz" \
    -C "$NEWROOT" \
    --numeric-owner


einfo "Installation completed successfully."
einfo "Cleaning temporary files..."

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
