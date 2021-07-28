#!/bin/bash
#add fix to exercise4-server1 here

echo '192.168.100.11 server2 server2' | sudo tee -a /etc/hosts

# generate server1 key
# echo "generating key for server1"
ssh-keygen -t rsa -f /vagrant/id_rsa -q -N ''

# deploy the key
# echo "deploying key on server1"
cp /vagrant/id_rsa /home/vagrant/.ssh/
chown vagrant /home/vagrant/.ssh/id_rsa

# allow no password ssh
# echo "adding to authorized_keys on server1"
cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys


