#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -z $1 ]; then
  echo "Usage: ./make-rpi.sh <hostname> <ip-suffix>"
  echo "       ./make-rpi.sh node-1 101"
  echo "       ./make-rpi.sh node-2 102"
  exit 1
fi

export DEV=mmcblk0
export IMAGE=ubuntu-20.04-preinstalled-server-arm64+raspi.img

if [ -z "$SKIP_FLASH" ];
then
  echo "Writing Raspbian Lite image to SD card"
  time dd if=$IMAGE of=/dev/$DEV bs=1M
fi

sync

echo "Mounting SD card from /dev/$DEV"

mount /dev/${DEV}p1 /mnt/rpi/boot
mount /dev/${DEV}p2 /mnt/rpi/root

# Add our SSH key
mkdir -p /mnt/rpi/root/home/ubuntu/.ssh/
cat ~/.ssh/id_rsa.pub > /mnt/rpi/root/home/ubuntu/.ssh/authorized_keys
chown -R 1000:1000 /mnt/rpi/root/home/ubuntu

# Disable password login
sed -ie s/#PasswordAuthentication\ yes/PasswordAuthentication\ no/g /mnt/rpi/root/etc/ssh/sshd_config

echo "Setting hostname: $1"
sed -ie s/ubuntu/$1/g /mnt/rpi/root/etc/hostname

# Set static IP

echo "network: {config: disabled}" > /mnt/rpi/root/etc/cloud/cloud.cfg.d/99-custom-networking.cfg
sed s/100/$2/g  99_config.yaml> /mnt/rpi/root/etc/netplan/99_config.yaml

echo "Unmounting SD Card"

umount /mnt/rpi/boot
umount /mnt/rpi/root

sync
