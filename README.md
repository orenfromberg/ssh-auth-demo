# ssh-ca-demo

## password-auth

First start the server and client:
```shell-script
docker compose up -d --build
docker compose run client
```

Now ssh into the server from the client:
```shell-script
root@laptop:/# ssh sshuser@server.mydomain.local
The authenticity of host 'server.mydomain.local (192.168.96.3)' can't be established.
ED25519 key fingerprint is SHA256:0No60RgzYcHmcq6XQzJtxeJJpQ5aQqvUikNyd3Gsi/0.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'server.mydomain.local' (ED25519) to the list of known hosts.
sshuser@server.mydomain.local's password: 
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```

log out of the server:

```shell-script
sshuser@server:~$ exit
logout
Connection to server.mydomain.local closed.
```

log out of the client:
```
root@laptop:/# exit
exit
```

tear everything down:
```
docker compose down
```