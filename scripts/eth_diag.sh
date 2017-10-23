
ports=$(ip link |grep enp | awk -F, '{print $1}' | sed 's/: <BROADCAST//g'|sed 's/[1-9]: *//g')

ret=0
for port in $ports;
do 
    result=$(ethtool  -t $port online | grep result | awk '{print $5}')
    if [ $result == "FAIL" ]
    then
	ret=1
	break
    fi
done

if [ $ret -eq 1 ]
then 
    echo "Ethernet interface diag FAILED: please check $port "
else
    echo "Ethernet interface diag Success"
fi
