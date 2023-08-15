#!/bin/bash

# delete all the old keys
# rm /etc/ssh/ssh_host_*
# create new keys
# ssh-keygen -A

# start the ssh server
exec /usr/sbin/sshd -D