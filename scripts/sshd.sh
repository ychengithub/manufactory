base=`dirname 0`
systemctl start sshd.service
[ ! -d "/root/.ssh" ] && mkdir /root/.ssh
chmod 700 /root/.ssh
cp $base/authorized_keys  /root/.ssh/
chmod 600 /root/.ssh/authorized_keys


