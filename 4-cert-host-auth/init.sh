#!/usr/bin/env bash

rm -rf ca client server
mkdir -p ca client server

# create certificate authority (CA) key pair
ssh-keygen -t rsa -N '' -C 'ca@mydomain.local' -f ca/id_rsa

# create client ssh key
ssh-keygen -t ed25519 -N '' -C sshuser@laptop.mydomain.local -f client/id_ed25519

# create server key pair
ssh-keygen -t ed25519 -N '' -C root@server.mydomain.local -f server/id_ed25519

# write the client public key to the server authorized_keys
cat client/id_ed25519.pub > server/authorized_keys

# sign the server public key with the ca private key
ssh-keygen -s ca/id_rsa -h -I server.mydomain.local -n server.mydomain.local server/id_ed25519.pub 

# write the CA public key to the clients known_hosts file
cat <<EOF > client/known_hosts
@cert-authority *.mydomain.local $(cat ca/id_rsa.pub)
EOF