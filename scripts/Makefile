
run: sync
	ssh target /bin/sh -x /mnt/inst.sh
grub: sync
	ssh target /bin/sh -x /mnt/grub.sh

sync:
	scp inst.sh grub.sh sshd.sh target:/mnt
