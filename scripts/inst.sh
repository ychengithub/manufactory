
base=`dirname $0`
dstdev=/dev/sdb
boot="$dstdev"1
lvm="$dstdev"2
vg=VolGroup
lvsize=860160000S
swsize=66076672S 
bootarch=boot.tar.bz2
rootarch=cl_archiso-root.tar.bz2
bootqcow=sda1.qcow2
rootqcow=VolGroup-lv_root.qcow2
mbr=sda.mbr.dd


echo base is $base

#vgchange -an $vg
vgchange -an 

# empty the GTP label
dd if=$mbr of=$dstdev

parted -s $dstdev mklabel msdos
parted  $dstdev <<EOF
mkpart  primary ext4 2048s 1026047s 
mkpart	primary 1026048s  1952448511s
set 2 lvm on
unit s
p
EOF

e2image -ra $bootqcow $boot
#mkfs.ext4 $boot
#e2label $boot /boot

pvcreate -ff -y $lvm
pvs --unit s
vgcreate $vg $lvm
vgs --unit s
lvcreate  -y -L $lvsize -n lv_root $vg
lvcreate  -y -L $swsize -n lv_swap $vg
lvcreate  -y -L 127200000S -n lv_home $vg
lvcreate  -y -L 184350464S -n lv_bglog $vg
lvs --unit s

e2image -ra $rootqcow /dev/mapper/$vg-lv_root
mkswap /dev/mapper/$vg-lv_swap
mkfs.ext4 /dev/mapper/$vg-lv_home
mkfs.ext4 /dev/mapper/$vg-lv_bglog


#mkswap /dev/mapper/$vg-lv_swap
#mkfs.ext4 /dev/mapper/$vg-lv_root

[ ! -d /img ] && mkdir /img
mount /dev/mapper/$vg-lv_root /img
[ ! -d /img/boot ] && mkdir /img/boot
#tar jxvf $base/$rootarch -C /img
#tar jxvf $base/$bootarch -C /img/boot

mount -t proc proc /img/proc
mount -o bind /dev /img/dev
mount -t sysfs sys /img/sys
mount -o bind /dev/pts /img/dev/pts

#chroot /img /usr/sbin/grub2-install --boot-directory=/boot $dstdev
chroot /img/ /bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/mount $boot /boot
cp device.map /img/boot/grub
chroot /img  /bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /sbin/grub-install $dstdev

# need to update fstab due to uuid change

umount $boot
umount /img/dev/pts
umount /img/dev
umount /img/sys
umount /img/proc
umount /img

vgchange -an $vg


