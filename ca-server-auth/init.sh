#!/usr/bin/env bash

rm -rf ca client server
mkdir -p ca client server/.ssh server/ssh

# create certificate authority (CA) key pair
yes | ssh-keygen -t rsa -N '' -C 'ca@mydomain.local' -f ca/id_rsa
chmod 600 ca/id_rsa

# create client key pair
yes | ssh-keygen -t ed25519 -N '' -C sshuser@laptop.mydomain.local -f client/id_ed25519

# put the client public key in the server authorized_keys file
cat client/id_ed25519.pub > server/.ssh/authorized_keys

# create server key pair
yes | ssh-keygen -t ed25519 -N '' -C sshuser@laptop.mydomain.local -f server/ssh/id_ed25519

# sign the server public key with the ca private key
ssh-keygen -s ca/id_rsa -h -I server.mydomain.local server/ssh/id_ed25519.pub 

# write the CA public key to the clients known_hosts file
cat <<EOF > client/known_hosts
@cert-authority *.mydomain.local $(cat ca/id_rsa.pub)
EOF