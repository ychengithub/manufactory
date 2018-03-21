#!/bin/bash
echo "3 4 1 3" > /proc/sys/kernel/printk

export TERM=linux
disk=`fdisk -l /dev/sda | grep 'Disk /'`
clear

base=`dirname $0`
base=`realpath "$base"`
logfile=$base/inst.log
[ -f $logfile ] && mv $logfile $base/prev-inst.$$.log

function log_info ()
{
DATE_N=`date "+%Y-%m-%d %H:%M:%S"`
echo "${DATE_N} execute $0 [INFO] $@" >>$logfile 

}

#exec 3>&1 1>>${logfile} 2>&1

srcdev=`mount | grep " / " | cut -d ' ' -f 1`

matching_3000="23438819328 sectors" # 3000 install disk
matching_1000="5860533168 sectors" # 1000 install disk

# find a disk that has the matching size
disks_3000=( `fdisk -l | grep  "$matching_3000" | cut -d " " -f 2 | cut -d : -f 1` )
disks_1000=( `fdisk -l | grep  "$matching_1000" | cut -d " " -f 2 | cut -d : -f 1` )

if [ ${#disks_3000[@]} == 1 ]; then
        ISP="ISP3000"
	dialog --backtitle "ISP Installation System" --title "Disk Checking Success" \
		--infobox "$ISP disk $disks_3000 found: $matching_3000" 5 60; sleep 2
	log_info "Install disk matching 3000 $matching_3000 found: $disks_3000" 
	dstdev=${disks_3000[0]}
	boot_start=2048s
	boot_end=1026047s
	lvm_start=1026048s
	lvm_end=23438819294s
	root_size=419430400S
	swap_size=66076672S
	home_size=11166916608S
	bglog_size=10942308352S
	change_network=$base/network_config/change_network_3000.sh
	restart_udev=$base/network_config/restart_udev_3000.sh
	grubconf=
elif [ ${#disks_1000[@]} == 1 ]; then
        ISP="ISP1000"
	dialog --backtitle "ISP Installation System" --title "Disk Checking Success" \
		--infobox "$ISP disk $disks_1000 found: $matching_1000" 5 60; sleep 2
	log_info "Install disk matching 1000 $matching_1000 found: $disks_1000"
	dstdev=${disks_1000[0]}
	boot_start=2048s
	boot_end=1026047s
	lvm_start=1026048s
	lvm_end=5860533134s
	root_size=314572800S
	swap_size=66076672S
	home_size=2422751232S
	bglog_size=2422759424S
	change_network=$base/network_config/change_network_1000.sh
	restart_udev=$base/network_config/restart_udev_1000.sh
	grubconf=$base/1000/grub.conf
	# home_size = 50%FREE
	# vglog_size = 50%FREE
else
    dialog  --backtitle "ISP Installation System" --title "Disk Checking Failed" --msgbox "Can not find exactly one disk mathching ISP3000 or ISP1000" 5 60
    log_info "can not find exactly one disk mathching 3000 or 1000"
    exit
fi

log_info "installing on $dstdev from $srcdev" 
dialog  --backtitle "ISP Installation System"  --title "$ISP Installation" --infobox "Start to install system to $dstdev from $srcdev" 5 60 ; sleep 1

exec 3>&1 1>>${logfile} 2>&1
bootdev="$dstdev"1
lvmdev="$dstdev"2
vg=VolGroup

#Name of the logical volume name
lv_root=lv_root
lv_swap=lv_swap
lv_home=lv_home
lv_bglog=lv_bglog

bootarch=lvboot-selinux.tar.gz
rootarch=lvroot-selinux.tar.gz
homearch=lvhome-selinux.tar.gz
mbr=sda.mbr.dd

log_info "base is $base"

#vgchange -an $vg
vgchange -an 

# for tar --selinux
ln -sf $base/libselinux.so.1 /lib64

exec 1>/dev/tty
log_info "creating partition on $dstdev"
dialog --backtitle "ISP Installation System"  --title "$ISP Installation" --infobox "Creating partition on $dstdev..." 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1
# empty the GTP label
dd if=$base/$mbr of=$dstdev

parted -s $dstdev mklabel gpt
parted  $dstdev <<EOF
unit s
mkpart  primary ext4 $boot_start $boot_end
mkpart	primary $lvm_start $lvm_end
set 2 lvm on
set 1 boot on
p
EOF

exec 1>/dev/tty
log_info "creating boot filesystem on $bootdev" 
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Creating boot filesystem on $bootdev" 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1
mkfs.ext4 -F -F -O "^64bit" $bootdev 
e2label $bootdev /boot  

exec 1>/dev/tty
log_info "creating volume group $vg"
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Creating volume group $vg" 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1

pvcreate -ff -y $lvmdev
pvs --unit s
vgcreate $vg $lvmdev
vgs --unit s

lvcreate  -y -L $root_size -n $lv_root $vg
lvcreate  -y -L $swap_size -n $lv_swap $vg
lvcreate  -y -L $home_size -n $lv_home $vg
lvcreate  -y -L $bglog_size -n $lv_bglog $vg
lvs --unit s
vgs --unit s

exec 1>/dev/tty
log_info "creating file system inside volume group $vg" 
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Creating file system in volume group $vg" 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1
mkfs.ext4 -F -F -O "^64bit"  /dev/mapper/$vg-$lv_root 
mkswap /dev/mapper/$vg-$lv_swap
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-$lv_home 
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-$lv_bglog 


exec 1>/dev/tty
log_info "installing system files"
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Installing system files" 5 60 ; sleep 1 


[ ! -d /img ] && mkdir /img
mount /dev/mapper/$vg-$lv_root /img
[ ! -d /img/boot ] && mkdir /img/boot
time pv $base/$rootarch 2>&3 | $base/tar --selinux -zxf - -C /img
mount $bootdev /img/boot
time pv $base/$bootarch 2>&3 | $base/tar --selinux -zxf - -C /img/boot

#update fstab using label instead of UUID
sed -i '/\/boot/c\LABEL=\/boot \/boot ext4 defaults 1 2' /img/etc/fstab

touch /img/root/factory_flag
cp -fr $base/rc.local /img/etc/
cp -fr $base/save_config /img/usr/bin/
cp -fr $base/update_dev_id.sh /img/usr/local/bin
cp -fr $base/device_config /img/root/
cp -fr $base/crontab.txt /img/root/
mkdir /img/root/network_config
cp -fr $base/network_config/ifcfg-* /img/root/network_config
cp -fr $base/network_config/cover.sh /img/root/network_config
cp -fr $change_network /img/root/network_config/change_network.sh
cp -fr $restart_udev /img/root/network_config/restart_udev.sh

umount /img/boot

log_info "instaling home partition"
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Installing home partition" 5 60 ; sleep 1 
[ ! -d /home ] && mkdir /home
mount /dev/mapper/$vg-$lv_home /home
$base/tar --selinux -zxf $base/$homearch -C /home

log_info "installing bglog partition"
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Installing bglog partition" 5 60 ; sleep 1 
[ ! -d /bglog ] && mkdir /bglog
mount /dev/mapper/$vg-$lv_bglog /bglog
mkdir -p /bglog/BGdata
mkdir -p /bglog/sub_node.ext

log_info "installing bootloader" 
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Installing bootloader" 5 60 ; sleep 1 
mount -t proc proc /img/proc
mount -o bind /dev /img/dev
mount -t sysfs sys /img/sys
mount -o bind /dev/pts /img/dev/pts

exec 3>&1 1>>${logfile} 2>&1
##chroot /img /usr/sbin/grub2-install --boot-directory=/boot $dstdev
chroot /img/ /bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/mount $bootdev /boot
cp /img/boot/grub/device.map /tmp/device.map
echo "# this device map was generated by inst.sh" > /img/boot/grub/device.map
echo "(hd0)    $dstdev" >> /img/boot/grub/device.map
cat /img/boot/grub/device.map
[ ! -z $grubconf ] && cp $grubconf /img/boot/grub/

chroot /img  /bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /sbin/grub-install $dstdev
cp -f /tmp/device.map /img/boot/grub/device.map

exec 1>/dev/tty
log_info "umounting file systems and flushing cache to disk"
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Umounting file systems and flushing cache to disk" 5 60 ; sleep 1 
umount $bootdev
umount /img/dev/pts
umount /img/dev
umount /img/sys
umount /img/proc
umount /img
umount /home
umount /bglog

log_info "taking factory snapshot" 
dialog --backtitle "ISP Installation System" --title "$ISP Installation" --infobox "Making Factory Backup" 5 60 ; sleep 1 
lvcreate -y -L 200G -s -n $lv_root.factory $vg/$lv_root 1>>$logfile
lvcreate -y -L 200G -s -n $lv_root.recent $vg/$lv_root 1>>$logfile
#lvcreate -y -L 1024000S -n lv_boot $vg
#partclone.ext4 -b -s $bootdev -o /dev/$vg/lv_boot
#e2label /dev/$vg/lv_boot /boot.mirror
#lvcreate -y -L 200M -s -n lv_boot.factory $vg/lv_boot

log_info "install on $dstdev done" 
dialog --backtitle "ISP Installation System" --title "$ISP Installation " --msgbox "Install on $dstdev finished \n\nPress OK to reboot system" 5 60
exec 3>&1 1>>${logfile} 2>&1
vgchange -an $vg
sync
reboot -fn
