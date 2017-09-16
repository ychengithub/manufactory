base=`dirname 0`
cp $base/keys/* /etc/ssh/
chmod 600 /etc/ssh/*key*
#ifconfig enp2s0f0 192.168.10.135 up
#systemctl start sshd.service
service sshd restart
[ ! -d "/root/.ssh" ] && mkdir /root/.ssh
chmod 700 /root/.ssh
cp $base/authorized_keys  /root/.ssh/
chmod 600 /root/.ssh/authorized_keys


