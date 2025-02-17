#!/bin/bash
# for ZS-ISP3000B, 4 1G network cards, 4 10G network cards

LOCK_FILE="change_network.lock"

if [ -f "$LOCK_FILE" ]; then
echo "Error! change_network run over 1 time!"
exit 1
fi

echo "" > $LOCK_FILE

eth0=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth9/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth1=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth8/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth2=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth7/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth3=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth6/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth4=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth5/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth5=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth4/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth6=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth3/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth7=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth2/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth8=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth0/) {print a[j+1];exit}}'  | awk '{print $2}'`
eth9=`ip addr list  | awk '{a[NR]=$0}END{for (j=1;j<=NR;j++) if (a[j]~/ eth1/) {print a[j+1];exit}}'  | awk '{print $2}'`


RULE_FILE="/etc/udev/rules.d/70-persistent-net.rules"
cat>$RULE_FILE<<EOF

# This file was automatically generated by the /lib/udev/write_net_rules
# program, run by the persistent-net-generator.rules rules file.
#
# You can modify it, as long as you keep each rule on a single
# line, and change only the value of the NAME= key.

# PCI device 0x8086:0x1572 (i40e)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"

# PCI device 0x8086:0x1572 (i40e)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth1", ATTR{type}=="1", KERNEL=="eth*", NAME="eth1"

# PCI device 0x8086:0x1572 (i40e)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth2", ATTR{type}=="1", KERNEL=="eth*", NAME="eth2"

# PCI device 0x8086:0x1572 (i40e)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth3", ATTR{type}=="1", KERNEL=="eth*", NAME="eth3"

# PCI device 0x8086:0x1521 (igb)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth4", ATTR{type}=="1", KERNEL=="eth*", NAME="eth4"

# PCI device 0x8086:0x1521 (igb)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth5", ATTR{type}=="1", KERNEL=="eth*", NAME="eth5"

# PCI device 0x8086:0x1521 (igb)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth6", ATTR{type}=="1", KERNEL=="eth*", NAME="eth6"

# PCI device 0x8086:0x1521 (igb)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth7", ATTR{type}=="1", KERNEL=="eth*", NAME="eth7"

# PCI device 0x8086:0x1521 (igb)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth8", ATTR{type}=="1", KERNEL=="eth*", NAME="eth8"

# PCI device 0x8086:0x1521 (igb)
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$eth9", ATTR{type}=="1", KERNEL=="eth*", NAME="eth9"
EOF


