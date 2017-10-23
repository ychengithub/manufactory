
choices=`dialog --stdout --backtitle "Checklist" --checklist "Test" 20 80 14 Eth "Ethernet Diagnostic" 1 Disk "Disk Diagnostic" 2 BIOS "BIOS Diagnostic" 3`

if [[ $choices =~ "Eth" ]]; then
	ports=$(ip link |grep enp | awk -F, '{print $1}' | sed 's/: <BROADCAST//g'|sed 's/[1-9]: *//g')
	port_num=`echo $ports|wc -w`
	result=0
	step=`expr 100 / $port_num`

declare -i PERCENT=0
(
        for port in $ports;
        do
		echo "XXX"
                echo "Diagnostic the port $port ..."
                echo "XXX"
		echo $PERCENT
                #return=$(ethtool  -t $port online)
                return=$(ethtool  -t $port online | grep result | awk '{print $5}')
        	let PERCENT+=$step
		sleep 0.1
                if [[ $return =~ "FAIL" ]]
                then
                        result=1
                        break
                fi
        done
) | dialog --title "Ethernet Diagnostic" --gauge "Starting Diagnostic..." 20 50 14
	
	if [ $result -eq 1 ]
	then
		dialog   --title   "Ethernet Diag" --msgbox "Ethernet interface diag FAILED: please check $port" 10  50 
	else
		dialog   --title   "Ethernet Diag" --msgbox "Ethernet interface diag Success" 10  50
	fi
fi

if [[ $choices =~ "Disk" ]]; then

matching_3000="23438819328 sectors" # 3000 install disk
matching_1000="5860533168 sectors" # 1000 install disk

# find a disk that has the matching size
disks_3000=( `fdisk -l | grep  "$matching_3000" | cut -d " " -f 2 | cut -d : -f 1` )
disks_1000=( `fdisk -l | grep  "$matching_1000" | cut -d " " -f 2 | cut -d : -f 1` )
ret=0
step=`expr 100 / 3`
if [ ${#disks_3000[@]} == 1 ]; then

declare -i PERCENT=0
(
    	for disk in {20,21,22}
        do
                echo "XXX"
                echo "Diagnostic the disk $disk..."
                echo "XXX"
                echo $PERCENT
	        smartctl -d sat+megaraid,$disk /dev/sda -t short -t force >/dev/null
	        sleep 70
        	result=$(smartctl -d sat+megaraid,$disk /dev/sda -l selftest | grep "# 1")
        	tmp=${result##*offline}
        	tmp1=${tmp%%[0-9]*}
        	let PERCENT+=$step
        	sleep 0.1
        	if [[ $tmp1 =~ "Completed without error" ]]; then
                	:
        	else
                	ret=1
                	break
        	fi
        done
) | dialog --title "Disk Diagnostic" --gauge "Starting Diagnostic..." 20 50 14

elif [ ${#disks_1000[@]} == 1 ]; then
    echo "1000 diag"
else
    echo "can not find exactly one disk mathching 3000 or 1000" 1>&3
    exit
fi

if [ $ret -eq 1 ]; then
	dialog   --title   "Disk Diag" --msgbox "Disk diag Failed, Please check $disk disk" 10  50
else
	dialog   --title   "Disk Diag" --msgbox "Disk diag Success" 10  50
fi

fi


if [[ $choices =~ "BIOS" ]]; then

results=$(dmidecode 2>/dev/null |grep  Status)
ret=0
oldIFS=$IFS
IFS=$'\n'
for result in $results
do
    #echo $result
    tmp=${result##*:}
    #echo $tmp
    if [[ $tmp =~ "OK" ]] || [[ $tmp =~ "Enabled" ]] || [[ $tmp =~ "No errors" ]] || [[ $tmp =~ "OUT OF SPEC" ]] || \
        [[ $tmp =~ "None" ]] || [[ $tmp =~ "Valid" ]]; then
        :
    else
        ret=1
        break
    fi

done


declare -i PERCENT=0
(
	echo "XXX"
        echo "Diagnostic the disk $disk..."
        echo "XXX"
        echo $PERCENT
        sleep 1
) | dialog --title "BIOS Diagnostic" --gauge "Starting Diagnostic..." 20 50 14


if [ $ret -eq 1 ]; then
                dialog   --title   "BIOS Diag" --msgbox "BIOS diag Failed, Please check BIOS for such error hint: $result" 10  50
else
                dialog   --title   "BIOS Diag" --msgbox "BIOS diag Success" 10  50
fi
IFS=$oldIFS

fi


