
base=`dirname $0`
base=`realpath "$base"`

dstdev=/dev/sdc

vgchange -ay VolGroup
lvconvert --merge VolGroup/lv_root.factory
lvcreate -s -L 10G -n lv_root.factory VolGroup/lv_root
partclone.ext4 -c -b -s /dev/VolGroup/lv_boot.factory -O /dev/sdc1
 

