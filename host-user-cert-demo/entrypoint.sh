#!/bin/bash

# create new ssh_host_ keys
rm /etc/ssh/ssh_host_*
ssh-keygen -A

# start a bash shell as pid 1
exec bash