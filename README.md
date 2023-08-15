# ssh-ca-demo

## password-auth

First start the server and client:
```
docker compose up -d --build
docker compose run client
```
Now ssh into the server from the client using the password `password`:
```
root@laptop:/# ssh sshuser@server
The authenticity of host 'server (172.29.0.3)' can't be established.
ED25519 key fingerprint is SHA256:0TWqTu3soSCfGbmIqhhHzp811iMaSNkPdgENCvWjKKU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'server' (ED25519) to the list of known hosts.
sshuser@server's password: 
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```
log out of the server:
```
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

## client-key-auth

run the initialization script to create the client key:

```
./init.sh
```

bring up the server and get a shell in the client:

```
docker compose up -d --build
docker compose run client
```

Start the ssh-agent and load the key:

```
sshuser@laptop:/$ eval $(ssh-agent) && ssh-add
Agent pid 9
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
```

Finally, ssh into the server using `ssh server`:

```
sshuser@laptop:/$ ssh server
The authenticity of host 'server (172.27.0.3)' can't be established.
ED25519 key fingerprint is SHA256:51CVwSt2MsAXU0jICkSXy/IVgdOlJ316on3Y6xj1mAg.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'server' (ED25519) to the list of known hosts.
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```