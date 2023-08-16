#!/usr/bin/env bash

rm -rf client server
mkdir -p client server

# create client ssh key
ssh-keygen -t ed25519 -N '' -C sshuser@laptop.mydomain.local -f client/id_ed25519

# create server key pair
ssh-keygen -t ed25519 -N '' -C root@server.mydomain.local -f server/id_ed25519

# write the client public key to the server authorized_keys
cat client/id_ed25519.pub > server/authorized_keys
