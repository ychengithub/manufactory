#!/bin/bash

service network stop
modprobe -r igb
udevadm control --reload-rules
udevadm trigger
modprobe igb
service network start
sleep 1


