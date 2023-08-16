#!/bin/bash

# start the ssh agent
eval "$(ssh-agent)"
# add the keys
ssh-add
# start a bash shell as pid 1
exec bash