#!/bin/bash
#add fix to exercise6-fix here

## check inputs and parse arguments
if (($# < 2)); then
  echo "Error: at least 2 arguments are required: [FILES] TARGET_PATH"
  exit 1;
else
  TARGET_PATH="${@: -1}"
  FILES="${@:1:$#-1}"
fi

echo "TARGET_PATH: ${TARGET_PATH}"
echo "FILES: ${FILES}"

# For root usage during provisioning we need to update the ssh configuration
USER=`whoami`
if [ $USER == 'root' ]; then
  echo "USER: ${USER}"
  cp -fpr /home/vagrant/.ssh/* ~/.ssh/
  chown root ~/.ssh/*
fi

# check the current host and set TARGET_SERVER
HOST_NAME=`cat /etc/hostname`
echo "HOST_NAME: ${HOST_NAME}"
case $HOST_NAME in
  "server1") TARGET_SERVER="server2" ;;
  *) TARGET_SERVER="server1" ;;
esac
echo "TARGET_SERVER: ${TARGET_SERVER}"

# run rsync to copy files between servers and print the total number of bytes copied
CMD="rsync -v ${FILES} ${TARGET_SERVER}:${TARGET_PATH}"

BYTES=$(exec $CMD | grep "total size" | awk '{print $4}')
echo ${BYTES}

exit 0