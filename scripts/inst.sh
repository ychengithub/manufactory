
#base=`dirname $0`
base=$(cd "$(dirname "$0")"; pwd)
dstdev=/dev/sdb
boot="$dstdev"1
lvm="$dstdev"2
vg=VolGroup
lvsize=860160000S
swsize=66076672S 
#bootarch=boot.tar.bz2
rootarch=lvroot-selinux.tar.gz
homearch=lvhome-selinux.tar.gz
mbr=sda.mbr.dd

echo base is $base

#vgchange -an $vg
vgchange -an 

# for tar --selinux
ln -sf $base/libselinux.so.1 /lib64

# empty the GTP label
dd if=$base/$mbr of=$dstdev

parted -s $dstdev mklabel msdos
parted  $dstdev <<EOF
mkpart  primary ext4 2048s 1026047s 
mkpart	primary 1026048s  1952448511s
set 2 lvm on
unit s
p
EOF

mkfs.ext4 -F -F -O "^64bit" $boot
e2label $boot /boot

pvcreate -ff -y $lvm
pvs --unit s
vgcreate $vg $lvm
vgs --unit s
lvcreate  -y -L $lvsize -n lv_root $vg
lvcreate  -y -L $swsize -n lv_swap $vg
lvcreate  -y -L 127205376S -n lv_home $vg
lvcreate  -y -L 184352768S -n lv_bglog $vg
lvs --unit s


mkfs.ext4 -F -F -O "^64bit"  /dev/mapper/$vg-lv_root

mkswap /dev/mapper/$vg-lv_swap
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-lv_home
mkfs.ext4  -F -F -O "^64bit" /dev/mapper/$vg-lv_bglog

[ ! -d /img ] && mkdir /img
mount /dev/mapper/$vg-lv_root /img
[ ! -d /img/boot ] && mkdir /img/boot
mount $boot /img/boot
$base/pv $base/$rootarch | $base/tar --selinux -zxvf >/dev/null - -C /img
umount /img/boot

[ ! -d /home ] && mkdir /home
mount /dev/mapper/$vg-lv_home /home
$base/pv $base/$homearch | $base/tar --selinux -zxvf >/dev/null - -C /home

[ ! -d /bglog ] && mkdir /bglog
mount /dev/mapper/$vg-lv_bglog /bglog
mkdir -p /bglog/BGdata
mkdir -p /bglog/sub_node.ext

mount -t proc proc /img/proc
mount -o bind /dev /img/dev
mount -t sysfs sys /img/sys
mount -o bind /dev/pts /img/dev/pts

##chroot /img /usr/sbin/grub2-install --boot-directory=/boot $dstdev
chroot /img/ /bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/mount $boot /boot
cp $base/device.map /img/boot/grub
chroot /img  /bin/env PATH=/bin:/usr/bin:/sbin:/usr/sbin /sbin/grub-install $dstdev

# need to update fstab due to uuid change

umount $boot
umount /img/dev/pts
umount /img/dev
umount /img/sys
umount /img/proc
umount /img
umount /home
umount /bglog


vgchange -an $vg
