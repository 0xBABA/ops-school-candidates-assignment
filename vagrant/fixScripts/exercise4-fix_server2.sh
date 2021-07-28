#!/bin/bash
#add fix to exercise4-server2 here

echo '192.168.100.10 server1 server1' | sudo tee -a /etc/hosts


# deploy the key
# echo "deploying key on server2"
cp /vagrant/id_rsa /home/vagrant/.ssh/
chown vagrant /home/vagrant/.ssh/id_rsa

# allow no password ssh
# echo "adding to authorized_keys on server2"
cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

# cleanup the shared key files
rm -rf /vagrant/id_rsa*