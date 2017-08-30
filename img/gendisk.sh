md5sum -c arch.iso.sum || exit 
cp archlinux-2017.08.01-x86_64.iso sdd.img
dd if=sdd.mbr of=sdd.img  conv=notrunc
cat sdd3 >> sdd.img
md5sum -c sdd.img.sum || exit 

