#!/bin/bash
echo "3 4 1 3" > /proc/sys/kernel/printk

export TERM=linux
disk=`fdisk -l /dev/sda | grep 'Disk /'`
clear

export TERM=linux
disk=`fdisk -l /dev/sda | grep 'Disk /'`
dialog --title "Message" --yesno "Continue install to $disk" 10 70 || exit
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
        isp="ISP3000"
	dialog --title "ISP3000 Installation" --infobox "Install to disk $disks_3000 : $matching_3000" 5 60; sleep 2
	clear 
	log_info "Install disk matching 3000 $matching_3000 found: $disks_3000" 
elif [ ${#disks_1000[@]} == 1 ]; then
        isp="ISP1000"
	dialog --title "ISP1000 Installation" --infobox "Install to disk $disks_1000 : $matching_1000" 5 60; sleep 2 
	clear
	log_info "Install disk matching 1000 $matching_1000 found: $disks_1000"
fi

if [ ${#disks_3000[@]} == 1 ]; then
        ISP="3000"
	dstdev=${disks_3000[0]}
	boot_start=2048s
	boot_end=1026047s
	golden_start=1026048s
	golden_end=5220351s
	lvm_start=5220352s
	lvm_end=23438819294s
	root_size=419430400S
	swap_size=66076672S
	home_size=11166916608S
	bglog_size=10942308352S
	change_network=$base/network_config/change_network_3000.sh
	restart_udev=$base/network_config/restart_udev_3000.sh
	grubconf=
elif [ ${#disks_1000[@]} == 1 ]; then
        ISP="1000"
	dstdev=${disks_1000[0]}
	boot_start=2048s
	boot_end=1026047s
	golden_start=1026048s
	golden_end=5220351s
	lvm_start=5220352s
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
    log_info "can not find exactly one disk mathching 3000 or 1000"
    exit
fi

log_info "installing on $dstdev from $srcdev" 
dialog --title "$ISP Installation" --infobox "installing on $dstdev from $srcdev" 5 60 ; sleep 1

bootdev="$dstdev"1
goldev="$dstdev"2
lvmdev="$dstdev"3
vg=VolGroup

#Name of the logical volume name
lv_root=lv_root
lv_swap=lv_swap
lv_home=lv_home
lv_bglog=lv_bglog

#bootarch=boot.tar.bz2
rootarch=lvroot-selinux.tar.gz
homearch=lvhome-selinux.tar.gz
mbr=sda.mbr.dd

log_info "base is $base"

#vgchange -an $vg
vgchange -an 

# for tar --selinux
ln -sf $base/libselinux.so.1 /lib64

log_info "creating partition on $dstdev"
dialog --title "$ISP Installation" --infobox "creating partition on $dstdev..." 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1
# empty the GTP label
dd if=$base/$mbr of=$dstdev

parted -s $dstdev mklabel gpt
parted  $dstdev <<EOF
unit s
mkpart  primary ext4 $boot_start $boot_end
mkpart  primary ext4 $golden_start $golden_end
mkpart	primary $lvm_start $lvm_end
set 3 lvm on
set 2 boot on
p
EOF

exec 1>/dev/tty
log_info "creating boot filesystem on $bootdev" 
dialog --title "$ISP Installation" --infobox "creating boot filesystem on $bootdev" 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1
mkfs.ext4 -F -F -O "^64bit" $bootdev 
e2label $bootdev /boot  

mkfs.ext4 -F -F -O "^64bit" $goldev
e2label $goldev golden

exec 1>/dev/tty
log_info "installing golden partition" 
dialog --title "$ISP Installation" --infobox "installing golden partition" 5 60 ; sleep 1 
[ ! -d /img ] && mkdir /img
mount $goldev /img

[ ! -d /src ] && mkdir /src
mount $srcdev /src
cp -ra /src/{bin,boot,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var} /img

# need to update fstab due to uuid change
cat > /img/etc/fstab <<EOF
LABEL=golden	/         	ext4      	rw,relatime,data=ordered	0 1

EOF

log_info "installing golden bootloader"
dialog --title "$ISP Installation" --infobox "installing golden bootloader" 5 60 ; sleep 1 

extlinux -i /img/boot/syslinux 
umount /src
umount /img

log_info "creating volume group $vg"
dialog --title "$ISP Installation" --infobox "creating volume group $vg" 5 60 ; sleep 1 

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
dialog --title "$ISP Installation" --infobox "creating file system inside volume group $vg" 5 60 ; sleep 1 

exec 3>&1 1>>${logfile} 2>&1
mkfs.ext4 -F -F -O "^64bit"  /dev/mapper/$vg-$lv_root 
mkswap /dev/mapper/$vg-$lv_swap
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-$lv_home
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-$lv_bglog


exec 1>/dev/tty
log_info "installing system files"
dialog --title "$ISP Installation" --infobox "installing system files" 5 60 ; sleep 1 

mkswap /dev/mapper/$vg-$lv_swap
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-$lv_home
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-$lv_bglog

echo "installing system files" 1>&3
[ ! -d /img ] && mkdir /img
mount /dev/mapper/$vg-$lv_root /img
[ ! -d /img/boot ] && mkdir /img/boot
mount $bootdev /img/boot
time pv $base/$rootarch 2>&3 | $base/tar --selinux -zxf - -C /img

#update fstab using label instead of UUID
sed -i '/\/boot/c\LABEL=\/boot \/boot ext4 defaults 1 2' /img/etc/fstab

touch /img/root/factory_flag
cp -fr $base/rc.local /img/etc/
cp -fr $base/save_config /img/usr/bin/
cp -fr $base/update_dev_id.sh /img/usr/local/bin
cp -fr $base/device_config /img/root/
mkdir /img/root/network_config
cp -fr $base/network_config/ifcfg-* /img/root/network_config
cp -fr $base/network_config/cover.sh /img/root/network_config
cp -fr $change_network /img/root/network_config/change_network.sh
cp -fr $restart_udev /img/root/network_config/restart_udev.sh

umount /img/boot

log_info "instaling home partition"
dialog --title "$ISP Installation" --infobox "installing home partition" 5 60 ; sleep 1 
[ ! -d /home ] && mkdir /home
mount /dev/mapper/$vg-$lv_home /home
$base/tar --selinux -zxf $base/$homearch -C /home

log_info "installing bglog partition"
dialog --title "$ISP Installation" --infobox "installing bglog partition" 5 60 ; sleep 1 
[ ! -d /bglog ] && mkdir /bglog
mount /dev/mapper/$vg-$lv_bglog /bglog
mkdir -p /bglog/BGdata
mkdir -p /bglog/sub_node.ext

log_info "installing bootloader" 
dialog --title "$ISP Installation" --infobox "installing bootloader" 5 60 ; sleep 1 
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
cp /boot/vmlinuz-linux /boot/initramfs-linux-fallback.img  /boot/initramfs-linux.img /img/boot
cat >>/img/boot/grub/grub.conf <<EOF
title Golden
	root (hd0,0)
	kernel /vmlinuz-linux root=LABEL=golden
	initrd /initramfs-linux.img
EOF

exec 1>/dev/tty
log_info "umounting file systems and flushing cache to disk"
dialog --title "$ISP Installation" --infobox "umounting file systems and flushing cache to disk" 5 60 ; sleep 1 
umount $bootdev
umount /img/dev/pts
umount /img/dev
umount /img/sys
umount /img/proc
umount /img
umount /home
umount /bglog

log_info "taking factory snapshot" 
dialog --title "$ISP Installation" --infobox "taking snapshots" 5 60 ; sleep 1 
lvcreate -y -L 200G -s -n $lv_root.factory $vg/$lv_root 1>>$logfile
lvcreate -y -L 200G -s -n $lv_root.recent $vg/$lv_root 1>>$logfile
#lvcreate -y -L 1024000S -n lv_boot $vg
#partclone.ext4 -b -s $bootdev -o /dev/$vg/lv_boot
#e2label /dev/$vg/lv_boot /boot.mirror
#lvcreate -y -L 200M -s -n lv_boot.factory $vg/lv_boot

log_info "install on $dstdev done" 
dialog --title "ISP3000 Installation " --infobox "Install on $dstdev finished" 5 60; sleep 2
exec 3>&1 1>>${logfile} 2>&1
vgchange -an $vg
