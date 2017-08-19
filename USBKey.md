
How to create the bootable USB Key Fresh install
================================================

* Currently using ArchLinux install iso as the base.
* Download the ARchLinux [ISO 650MB](https://www.archlinux.org/download/)
* Using dd to dump the iso image to the usb key  
  Assume the usb key device is **/dev/sdf**  
  **Pleae change the /dev/sdf to your local USB key device name**

	```
	sudo dd if=archlinux-2017.08.01-x86_64.iso of=/dev/sdf status=progress
	```
* Create data partition after the ios image. Partition number is **3**, size is default which take up the rest of the USB key.

	```
	$ sudo fdisk /dev/sdf

	Command (m for help): p
	Disk /dev/sdc: 14.7 GiB, 15733161984 bytes, 30728832 sectors
	Units: sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disklabel type: dos
	Disk identifier: 0x282bad86

	Device     Boot   Start      End  Sectors  Size Id Type
	/dev/sdc1  *          0  1056767  1056768  516M  0 Empty
	/dev/sdc2           164   131235   131072   64M ef EFI (FAT-12/16/32)

	Command (m for help): n
	Partition type
	   p   primary (2 primary, 0 extended, 2 free)
	   e   extended (container for logical partitions)
	Select (default p): p
	Partition number (3,4, default 3): 
	First sector (1056768-30728831, default 1056768): 
	Last sector, +sectors or +size{K,M,G,T,P} (1056768-30728831, default 30728831): 

	Created a new partition 3 of type 'Linux' and of size 14.2 GiB.

	Command (m for help): w
	The partition table has been altered.
	Calling ioctl() to re-read partition table.

	$
	```
* Create ext4 file system in the new partition /dev/sdf3

	```
	sudo mkfs.ext4 /dev/sdf3
	```

* Create label name 'data' for the new ext4 partition on /dev/sdf3.
  This step is very important, without a label the archlinux boot up script will get confused this data partition as the iso file storage partition. It will not able to mount the iso image.

	```
	sudo e2label /dev/sdf3 data
	```
* Create mount point

	```
	sudo mkdir -p /mnt/usb
	```

* Mount data partition:

	```
	sudo mount /dev/sdf3 /mnt/usb
	```

* Copy boot.tgz and root.tgz into data partition.
  The file name need to match the install script.

	```
	sudo cp boot.tar.bz2 cl_archiso-root.tar.bz2 /mnt/usb
	```

* Copy install script and ssh setup script into data partition.

	```
	sudo cp -r scripts/* /mnt/usb
	```
* umount data partition

	```
	sudo umount /mnt/usb
	```


* flash cached data into usb key before eject the key.

	```
	sync
	```

