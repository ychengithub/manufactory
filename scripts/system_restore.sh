echo "3 4 1 3" > /proc/sys/kernel/printk

tempfile=/tmp/restore_option
logfile=/var/log/system_restore.log

base=`dirname $0`
base=`realpath "$base"`
bootarch=lvboot-selinux.tar.gz

bghome="/mnt/home/BGhome"
bgsftp="/mnt/home/BGsftp"
bgview="/mnt/home/BGsftp/view"
bgtickets="/mnt/home/BGsftp/tickets"
bgwsa="/mnt/home/BGsftp/wsa_download"
bgftp_transfer="/mnt/home/BGsftp/ftp_transfer"


ln_bghome="/mnt/root/BGhome"
ln_bgsftp="/mnt/root/BGsftp"
ln_bgdata="/mnt/root/BGdata"

subnode="/mnt/BGlog/sub_node.ext"
bgdata="/mnt/BGlog/BGdata"

home_dir_list=("$bghome" "$bgsftp" "$bgview" "$bgtickets" "$bgwsa" "$bgftp_transfer")
bglog_dir_list=("$subnode" "$bgdata")
ln_dir_list=("$ln_bghome" "$ln_bgsftp" "$ln_bgdata")
source_dir_list=("$bghome" "$bgsftp" "$bgdata")

boot_mnt="/mnt/boot"
home_mnt="/mnt/home"
bglog_mnt="/mnt/BGlog"
root_mnt="/mnt/root"
predefined_boot_size=29764452

temp_dir_list=("$boot_mnt" "$home_mnt" "$bglog_mnt" "$root_mnt")

home_vol="/dev/VolGroup/lv_home"
root_vol="/dev/VolGroup/lv_root"
bglog_vol="/dev/VolGroup/lv_bglog"



matching_3000="23438819328 sectors" # 3000 install disk
matching_1000="5860533168 sectors" # 1000 install disk

# find a disk that has the matching size
disks_3000=( `fdisk -l | grep  "$matching_3000" | cut -d " " -f 2 | cut -d : -f 1` )
disks_1000=( `fdisk -l | grep  "$matching_1000" | cut -d " " -f 2 | cut -d : -f 1` )

if [ -n "$disks_3000" ]; then
	bootdev=${disks_3000}1
elif [ -n "$disks_1000" ]; then
	bootdev=${disks_1000}1
fi 

dialog --backtitle "ISP System Restore" --clear --title "Restore Option" --menu "Use the UP/DOWN arrow keys, the first \n\
letter of the choice as a hot key, or the \n\
number keys 1-9 to choose an option.\n\n\
Choose an Item:" 20 51 4 \
"Factory" "Restore Factory Configuration" \
"Recent" "Restore recent daily configuration" \
"Other" "Restore boot, BGlog and BGhome" 2>$tempfile

exec 3>&1 1>>${logfile} 2>&1

retval=$?
choice=`cat $tempfile`

case $retval in
0)
	case $choice in
                "Other")
                vgchange -ay VolGroup
		for dir in ${temp_dir_list[@]}; do
    			if [ ! -d $dir ]; then
				echo "$dir not exist"
				mkdir -p $dir
    			fi
		done
		mount $bootdev $boot_mnt
		mount $home_vol $home_mnt
		mount $bglog_vol $bglog_mnt
		mount $root_vol $root_mnt
		echo "mount $bootdev $boot_mnt"
		echo "mount $home_vol $home_mnt"
		echo "mount $bglog_vol $bglog_mnt"
		echo "mount $root_vol $root_mnt"

                touch /mnt/root/root/restore_flag
                count=`grep 'restore_flag' /mnt/root/etc/rc.local | wc -l`
                if [ -f /mnt/root/etc/rc.local ]; then
                    if [ $count -eq 0 ]; then
                        cat $base/restore_rc.local >>/mnt/root/etc/rc.local
                    fi
                else
                    cp -fr $base/rc.local /mnt/root/etc/
                fi

		boot_size=`find $boot_mnt -type f -exec ls -l {} \; | awk 'BEGIN{sum=0}{sum+=$5}END{print sum}'`
		#boot_dir_cmp_result=`diff -urNa $boot_mnt $base/boot_dir`
                exec 1>/dev/tty
		if [ $boot_size -eq $predefined_boot_size ]; then
			dialog --backtitle "ISP System Restore" --title "ISP Restore" --infobox "Boot partition is OK" 5 60 ; sleep 1
                	exec 3>&1 1>>${logfile} 2>&1
			echo "boot size is $boot_size"
		else
			rm -fr $boot_mnt/*
			$base/tar --selinux -zxf $base/$bootarch -C $boot_mnt
			dialog --backtitle "ISP System Restore" --title "ISP Restore" --infobox "Boot partition is restored" 5 60 ; sleep 1
                	exec 3>&1 1>>${logfile} 2>&1
			echo "boot size is $boot_size suppose to be $predefined_boot_size"
		fi

		dialog --backtitle "ISP System Restore" --title "ISP Restore" --infobox "Check home dir" 5 60 ; sleep 1
		#check home dir
                exec 3>&1 1>>${logfile} 2>&1
		for dir in ${home_dir_list[@]}; do
    			if [ ! -d $dir ]; then
        			echo "$dir doesn't exists."
				mkdir -p $dir
                                if [ "$dir" == "$bgtickets" ]; then
                                    chmod g+w $bgtickets
				fi
    			fi
		done
                exec 1>/dev/tty
		dialog --backtitle "ISP System Restore" --title "ISP Restore" --infobox "Check bglog dir" 5 60 ; sleep 1
		#check bglog dir
                exec 3>&1 1>>${logfile} 2>&1
		for dir in ${bglog_dir_list[@]}; do
    			if [ ! -d $dir ]; then
        			echo "$dir doesn't exists."
				mkdir -p $dir
    			fi
		done
                exec 1>/dev/tty
		dialog --backtitle "ISP System Restore" --title "ISP Restore" --infobox "Check link dir" 5 60 ; sleep 1
		#check link dir
                exec 3>&1 1>>${logfile} 2>&1
		for i in ${!ln_dir_list[@]}; do
                        dir=${ln_dir_list[$i]}
    			if [ ! -L $dir ]; then
        			echo "link $dir doesn't exists."
				rm -rf $dir
                                src_dir=${source_dir_list[$i]}
                                ln -s $src_dir $dir
    			fi
		done

		umount $boot_mnt
		umount $root_mnt
		umount $bglog_mnt
		umount $home_mnt
                rm -rf $boot_mnt
                rm -rf $root_mnt
                rm -rf $bglog_mnt
                rm -rf $home_mnt
                exec 1>/dev/tty
                dialog  --backtitle "ISP System Restore" --title   "Restore Finished" --clear --msgbox "Restore to Factory Configuration Finished\n\n\
Press OK to reboot system" 10  50
                ;;
		"Factory") 
		vgchange -ay VolGroup
		lvconvert --merge VolGroup/lv_root.factory
		lvcreate -s -L 10G -n lv_root.factory VolGroup/lv_root
		exec 1>/dev/tty
		dialog  --backtitle "ISP System Restore" --title   "Restore Finished" --clear --msgbox "Restore to Factory Configuration Finished\n\n\
Press OK to reboot system" 10  50
		;;
		"Recent") 
		vgchange -ay VolGroup
		lvconvert --merge VolGroup/lv_root.recent
		lvcreate -s -L 10G -n lv_root.recent VolGroup/lv_root
		exec 1>/dev/tty
		dialog  --backtitle "ISP System Restore" --title   "Restore Finished" --clear --msgbox "Restore to Recent Configuration Finished\n\n\
Press OK to reboot system" 10  50
		;;
		*) exit;;
		esac;;

1)
exit;;
255)
exit;;
esac

#delete old tempfiles
rm -f $tempfile
sync
reboot -fn
