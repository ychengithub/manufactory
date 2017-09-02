base=`dirname 0`
cp -a keys/* /etc/ssh/
chmod 600 /etc/ssh/*.pub
ifconfig enp2s0f0 192.168.10.135 up
systemctl start sshd.service
[ ! -d "/root/.ssh" ] && mkdir /root/.ssh
chmod 700 /root/.ssh
cp $base/authorized_keys  /root/.ssh/
chmod 600 /root/.ssh/authorized_keys


