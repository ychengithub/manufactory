#!/bin/bash

service network stop
modprobe -r igb
modprobe -r e1000e
udevadm control --reload-rules
udevadm trigger
modprobe igb
modprobe e1000e
service network start
sleep 1


