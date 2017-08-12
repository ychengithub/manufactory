
base=`dirname $0`
dstdev=/dev/sdg
boot="$dstdev"1
lvm="$dstdev"2
vg=cl_archiso
lvsize=25141248S
swsize=3031040S
bootarch=boot.tar.bz2
rootarch=cl_archiso-root.tar.bz2



echo base is $base

vgchange -an $vg

# empty the GTP label
dd if=/dev/zero of=$dstdev bs=1M count=2

parted -s $dstdev mklabel msdos
parted  $dstdev <<EOF
mkpart  primary ext4 2048s  2099199s
mkpart	primary 2099200s  30277631s
set 2 lvm on
unit s
p
EOF

mkfs.ext4 $boot

pvcreate -ff -y $lvm
pvs --unit s
vgcreate $vg $lvm
vgs --unit s
lvcreate  -y -L $lvsize -n root $vg
lvcreate  -y -L $swsize -n swap $vg
lvs --unit s

mkswap /dev/mapper/$vg-swap
mkfs.ext4 /dev/mapper/$vg-root

[ ! -d /img ] && mkdir /img
mount /dev/mapper/$vg-root /img
[ ! -d /img/boot ] && mkdir /img/boot
mount $boot /img/boot
tar jxvf $base/$rootarch -C /img
tar jxvf $base/$bootarch -C /img/boot

mount -t proc proc /img/proc
mount -o bind /dev /img/dev
mount -t sysfs sys /img/sys
mount -o bind /dev/pts /img/dev/pts

chroot /img /usr/sbin/grub2-install --boot-directory=/boot $dstdev

# need to update fstab due to uuid change

umount $boot
umount /img/dev/pts
umount /img/dev
umount /img/sys
umount /img/proc
umount /img

vgchange -an $vg


