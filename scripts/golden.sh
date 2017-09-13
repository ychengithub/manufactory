

logfile=/tmp/golden.log
#exec 3>&1 1>${logfile} 2>&1
exec 3>&1 

base=`dirname $0`
base=`realpath "$base"`

srcdev=`mount | grep " / " | cut -d ' ' -f 1`
matching="31129600 sectors"
# find a disk that has the matching size
disks=( `fdisk -l | grep  "$matching" | cut -d " " -f 2 | cut -d : -f 1` )
echo "Install disk matching $matching found: $disks" 1>&3

if [ ${#disks[@]} != 1 ]; then
    echo "can not find exactly one disk mathching $matching : $disks" 1>&3
    exit
fi

dstdev=${disks[0]}
echo "installing on $dstdev" 1>&3

rootdev="$dstdev"1
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

echo "creating partition on $dstdev" 1>&3
# empty the GTP label
dd if=/dev/zero of=$dstdev count=2048

parted -s $dstdev mklabel msdos
parted  $dstdev <<EOF
mkpart  primary ext4 2048s 2713599s
set 1 boot on 
unit s
p
EOF

echo "creating boot filesystem on $rootdev" 1>&3
# empty the GTP label
mkfs.ext4 -F -F -O "^64bit" $rootdev

e2label $rootdev golden

echo "installing system files" 1>&3
[ ! -d /img ] && mkdir /img
mount $rootdev /img

[ ! -d /src ] && mkdir /src
mount $srcdev /src

cp -ra /src/{bin,boot,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var} /img

echo "installing bootloader" 1>&3
extlinux -i /img/boot/syslinux

umount /src
umount /img
dd if=/usr/lib/syslinux/bios/mbr.bin of=$dstdev

echo "install on $dstdev done" 1>&3

