# key-demo

start up the server with
```
docker compose build
docker compose run server
```

then start sshd with
```
/usr/sbin/sshd -D &
```

in another terminal, start the client:
```
docker compose run client
```

create an ssh keypair:
```
ssh-keygen -t ed25519 -N 'keypass' -C sshuser@laptop.mydomain.local
```

scan the public key of the server:
```
ssh-keyscan server.mydomain.local >> ~/.ssh/known_hosts
```

copy they public key to the server:
```
ssh-copy-id server.mydomain.local
```

ssh to the server:
```
ssh server.mydomain.local
```

exit the server
exit the client
docker compose down