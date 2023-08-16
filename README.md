# ssh-auth-demo

This repo contains an exploration of various SSH authentication schemes that include:
* password authentication
* ssh client key authentication
* ssh client/server key authentication
* CA host certificate authentication
* CA host/client certificate authentication

Heavily based on this blog post: https://jameshfisher.com/2018/03/16/how-to-create-an-ssh-certificate-authority/

## 1-password-auth

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

## 2-key-client-auth

Now we will level up to using SSH keys to authenticate a client to a server.

Run the initialization script to create the client key:

```
./init.sh
```

bring up the server and get a shell in the client:

```
docker compose up -d --build
docker compose run client
```

After getting a shell in the client you should see the following:
```
Agent pid 8
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
sshuser@laptop:/$
```

This is the output from the entrypoint script doing two things:
1. starting the ssh agent
2. adding the private key as an identity

Now ssh into the server using `ssh server.mydomain.local`:

```
sshuser@laptop:/$ ssh server.mydomain.local
The authenticity of host 'server.mydomain.local (172.31.0.3)' can't be established.
ED25519 key fingerprint is SHA256:PzhrcmX8/01Bnw8ulG/n05FTu92G32eJrZ8NrDyTAh4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'server.mydomain.local' (ED25519) to the list of known hosts.
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```

clean up:
1. exit the server
2. exit the client
3. run `docker compose down`

## 3-key-client-server-auth

We'll build on key-client-auth to authenticate the server to the client.

To authenticate the server to the client, we need to add the servers public key to the clients `known_hosts` file.

We are doing it in the entryscript because the format of the `known_hosts` file makes it difficult to add the public key manually.

We'll use `ssh-keyscan` which will output the format we need.

1. ./init.sh
2. docker compose up -d --build
3. docker compose run client

```
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
Agent pid 9
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
sshuser@laptop:/$
```

now ssh to the server:

```
sshuser@laptop:/$ ssh server.mydomain.local
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$
```

smoothest login yet with no password and no prompting the user whether they want to trust the server.

## 4-cert-host-auth

```
./init.sh
docker compose up -d --build
docker compose run client
```
You'll see the agent loading the identity:
```
Agent pid 8
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
sshuser@laptop:/$
```

Now ssh to the server:
```
sshuser@laptop:/$ ssh server.mydomain.local
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```
## ca-server-auth

```
./init.sh
docker compose up -d --build
docker compose run client
```

Now ssh using the long hostname:

```
sshuser@laptop:/$ ssh server.mydomain.local
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```

## ca-client-auth

```
./init.sh
docker compose up -d --build
docker compose run client
```

Now ssh using the long hostname:

```
sshuser@laptop:/$ ssh server.mydomain.local
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```
