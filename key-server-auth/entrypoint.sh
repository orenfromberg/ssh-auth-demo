#!/bin/bash

# add the server public key to the client known hosts
ssh-keyscan server.mydomain.local >> ~/.ssh/known_hosts

# start the ssh agent
eval "$(ssh-agent)"
# add the keys
ssh-add
# start a bash shell as pid 1
exec bash