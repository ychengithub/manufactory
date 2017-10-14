echo fdisk -l
fdisk -l 

echo vgdisplay --unit s
vgdisplay --unit s

echo lvdisplay --unit s
lvdisplay --unit s

echo pvdisplay --unit s
pvdisplay --unit s

for d in `cat /proc/partitions | egrep "sd.$" | rev | cut -d ' ' -f 1 | rev`; do
	echo parted /dev/$d
	parted /dev/$d unit s print
done


