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

if [ $ret -eq 1 ]; then
	echo "BIOS diag Failed, Please check BIOS for such error hint: $result"
else
	echo "BIOS diag Success"
fi 
IFS=$oldIFS
