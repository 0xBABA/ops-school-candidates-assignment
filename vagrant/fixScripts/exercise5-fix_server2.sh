#!/bin/bash
#add fix to exercise5-server2 here

# echo "writing /home/vagrant/.ssh/config"
cat > /home/vagrant/.ssh/config <<EOF
Host server*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF