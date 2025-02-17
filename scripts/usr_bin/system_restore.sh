echo "3 4 1 3" > /proc/sys/kernel/printk

tempfile=/tmp/restore_option
logfile=/var/log/system_restore.log

dialog --clear --title "Restore Option" --menu "Use the UP/DOWN arrow keys, the first \n
letter of the choice as a hot key, or the \n\
number keys 1-9 to choose an option.\n\n\
Choose an Item:" 20 51 4 \
"Factory" "Restore Factory Configuration" \
"Recent" "Restore recently configuration" 2>$tempfile

exec 3>&1 1>>${logfile} 2>&1

retval=$?
choice=`cat $tempfile`

case $retval in
0)
	case $choice in
		"Factory") 
		vgchange -ay VolGroup
		lvconvert --merge VolGroup/lv_root.factory
		lvcreate -s -L 10G -n lv_root.factory VolGroup/lv_root
		exec 1>/dev/tty
		dialog   --title   "Restore Result" --clear --msgbox "Restore to Factory Configuration Finished" 10  50
		;;
		"Recent") 
		vgchange -ay VolGroup
		lvconvert --merge VolGroup/lv_root.recent
		lvcreate -s -L 10G -n lv_root.recent VolGroup/lv_root
		exec 1>/dev/tty
		dialog   --title   "Restore Result" --clear --msgbox "Restore to Recent Configuration Finished" 10  50
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
