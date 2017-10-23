matching_3000="23438819328 sectors" # 3000 install disk
matching_1000="5860533168 sectors" # 1000 install disk

# find a disk that has the matching size
disks_3000=( `fdisk -l | grep  "$matching_3000" | cut -d " " -f 2 | cut -d : -f 1` )
disks_1000=( `fdisk -l | grep  "$matching_1000" | cut -d " " -f 2 | cut -d : -f 1` )
ret=0
if [ ${#disks_3000[@]} == 1 ]; then
    for disk in {20,21,22}
    do 
#        smartctl -d sat+megaraid,$disk /dev/sda -t short -t force >/dev/null
#        sleep 70 
        result=$(smartctl -d sat+megaraid,$disk /dev/sda -l selftest | grep "# 1")
        tmp=${result##*offline}
        tmp1=${tmp%%[0-9]*}
        if [[ $tmp1 =~ "Completed without error" ]]; then
		:
        else
		ret=1
		break
	fi
    done
elif [ ${#disks_1000[@]} == 1 ]; then
    echo "1000 diag"
else
    echo "can not find exactly one disk mathching 3000 or 1000" 1>&3
    exit
fi

if [ $ret -eq 1 ]; then
	echo "Disk diag Failed, Please check $disk disk"
else
	echo "Disk diag Success"
fi 
