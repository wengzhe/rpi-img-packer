#!/bin/bash
echo "Installing needed packages..."
sudo apt-get install -y dosfstools parted kpartx rsync

echo "Cleaning apt & raspberrypi.* ..."
sudo apt-get clean && sudo apt-get autoclean
rm raspberrypi.img raspberrypi.tar.gz

df=`df -P | grep /dev/root | awk '{print $3}'`
dr=`df -P | grep /dev/mmcblk0p1 | awk '{print $2}'`
df=`echo $df $dr |awk '{print int(($1+$2)*1.1/1024+1)*1024}'`

echo "Making image size=${df}KB"
sudo dd if=/dev/zero of=raspberrypi.img bs=1K count=$df
sudo parted raspberrypi.img --script -- mklabel msdos
start=`sudo fdisk -l /dev/mmcblk0| awk 'NR==10 {print $2}'`
start=`echo $start's'`
end=`sudo fdisk -l /dev/mmcblk0| awk 'NR==10 {print $3}'`
end2=$[end+1]
end=`echo $end's'`
end2=`echo $end2's'`

echo "Making file systems"
sudo parted raspberrypi.img --script -- mkpart primary fat32 $start $end
sudo parted raspberrypi.img --script -- mkpart primary ext4 $end2 -1

loopdevice=`sudo losetup -f --show raspberrypi.img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
partBoot="${device}p1"
partRoot="${device}p2"
sleep 5
sudo mkfs.vfat -F 32 $partBoot
sudo mkfs.ext4 $partRoot

echo -e "Continue to copy files? (Y/N)\c"
read A
if [[ $A == Y* ]] || [[ $A == y* ]]; then
	sudo rm -rf /media/B
	sudo rm -rf /media/R
	sudo mkdir /media/B
	sudo mkdir /media/R
	sudo mount -t vfat $partBoot /media/B
	sudo mount -t ext4 $partRoot /media/R
	sudo cp -rfp /boot/* /media/B/
	cd /media/R
	sudo rsync -aP --exclude="raspberrypi.img" --exclude=".cache"  --exclude=/var/cache/* --exclude=/media/* --exclude=/run/* --exclude=/sys/* --exclude=/boot/* --exclude=/proc/* --exclude=/tmp/* --exclude=/var/swap --exclude=/var/lib/dhcpcd5/* --exclude=/var/lib/dhcp/* / ./ > /dev/null
	touch /media/R/var/lib/dhcp/dhclient.leases
	cd
	
	#在这里开始修改文件，先不umount
	echo -e "Umount now? (Y/N)\c"
	read B
	if [[ $B == Y* ]] || [[ $B == y* ]]; then
		sudo umount /media/B
		sudo umount /media/R

		sudo kpartx -d $loopdevice
		sudo losetup -d $loopdevice

		echo -e "Compress now? (Y/N)\c"
		read C
		if [[ $C == Y* ]] || [[ $C == y* ]]; then
			tar zcvf raspberrypi.tar.gz raspberrypi.img
		fi
	fi
else
	sudo kpartx -d $loopdevice
	sudo losetup -d $loopdevice
fi