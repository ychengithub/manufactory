
systemctl start sshd.service
[ ! -d "/root/.ssh" ] && mkdir -f /root/.ssh
chmod 700 /root/.ssh
cp $base/authorized_key  /root/.ssh/
chmod 600 /root/.ssh/authorized_key


