base=`dirname $0`
dstdev=/dev/sdb
boot="$dstdev"1
vg=VolGroup

vgchange -ay $vg
mount /dev/mapper/$vg-lv_root /img

mount -t proc proc /img/proc
mount -o bind /dev /img/dev
mount -t sysfs sys /img/sys
mount -o bind /dev/pts /img/dev/pts

#chroot /img /usr/sbin/grub2-install --boot-directory=/boot $dstdev
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

vgchange -an $vg


