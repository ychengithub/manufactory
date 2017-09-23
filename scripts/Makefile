
run: sync
	ssh target /bin/sh -x /mnt/inst/inst.sh
grub: sync
	ssh target /bin/sh -x /mnt/inst/grub.sh

push:
	scp inst.sh grub.sh sshd.sh target:/mnt/inst
