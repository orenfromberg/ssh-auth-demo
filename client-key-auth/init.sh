#!/usr/bin/env bash

# create client ssh key

rm -rf client server
mkdir -p client server
yes | ssh-keygen -t ed25519 -N '' -C sshuser@laptop.mydomain.local -f client/id_ed25519
cat client/id_ed25519.pub > server/authorized_keys