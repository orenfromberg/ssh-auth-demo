# ssh-auth-demo

This repo contains an exploration of various SSH authentication schemes that include:
* password authentication
* ssh client key authentication
* ssh client/server key authentication
* CA host certificate authentication
* CA host/client certificate authentication

Heavily based on this blog post: https://jameshfisher.com/2018/03/16/how-to-create-an-ssh-certificate-authority/

You will need docker and docker-compose to run these examples.

## Password Authentication

Password authentication is the most basic form of ssh authentication.

In this scheme a user must enter a password every time they ssh to a remote host.

To walk through this example, enter the following commands in your terminal:

```
cd 1-password-auth
./init.sh
docker compose run client
```

You will see the host shell prompt:
```
sshuser@laptop:/$ 
```

To ssh to the server, we don't need to give any other information other than the server name. This is because ssh will assume the current username and port 22 by default.

Enter `ssh server.mydomain.local` in the prompt and you should see something like the following:
```
The authenticity of host 'server.mydomain.local (192.168.224.3)' can't be established.
ED25519 key fingerprint is SHA256:PzhrcmX8/01Bnw8ulG/n05FTu92G32eJrZ8NrDyTAh4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```

The ssh client found a host named `server.mydomain.local` at ip `192.168.224.3` but it has no way to verify that it is who it says it is. Any server on the network could pretend to be the host named `server.mydomain.local`. This kind of attack is called a man in the middle (MitM) attack. Is this the real one?

The server provided a hint in the form of an ssh key fingerprint. This is derived from the private key used by the ssh server and is used to verify the authenticity and integrity of the server. If it looks familiar then it is safe to trust the host.

The client prompts the user to choose whether it wants to trust that it is connecting to the real server. If we say no then the client will accept that the host key verification was a failure and exit. 

If we say yes and verify the authenticity of the server then we get a new prompt:

```
Warning: Permanently added 'server.mydomain.local' (ED25519) to the list of known hosts.
sshuser@server.mydomain.local's password:
```

The client added the public key of the server to a file called `known_hosts`. When the client connects to a server, it checks to see if it has seen it before by looking up the mapping between the name and the public key.

Enter the password `password` and you should see the server banner and shell prompt:
```
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed Aug 16 12:08:23 2023 from 192.168.224.2
sshuser@server:~$
```
Exit the server with `exit` to go back to the client:

```
sshuser@server:~$ exit
logout
Connection to server.mydomain.local closed.
sshuser@laptop:/$ 
```

Connect again to the same server with `ssh server.mydomain.local` and we are only prompted for a password.

```
sshuser@laptop:/$ ssh server.mydomain.local
sshuser@server.mydomain.local's password: 
```

We do not get prompted to trust the host because ssh recognized the server in the `known_hosts` file.

Enter your password and you get the server banner message and shell prompt:

```
Linux server.mydomain.local 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed Aug 16 12:12:32 2023 from 192.168.224.2
sshuser@server:~$ 
```

enter `exit` to go back to the client, and `exit` again to go back to your local host.

Run `docker compose down` to bring down the docker containers and network.

## SSH Client Key Authentication

The next step is to disable password authentication on the server and using a client SSH key for authenticationinstead.

On the client we create an ssh key pair that consist of private and public keys.

 and then copy the public key to the server.

On the server side, the client public key will get copied to the `authorized_keys` file.

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

Now we will continue to add the clients public key to the servers `authorized_keys` file, but instead of adding the server's public key to the clients `known_hosts` file, we'll add the CA's public key to the `known_hosts` file.
Additionally, we'll create a host certificate and then copy it to the server and configure the server to serve it to the client to prove its authenticity.
The client will recieve the host certificate and know that the server is legit.

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

## 5-cert-host-client-auth

Finally, we'll continue to use the host certificate to prove the server is authentic but we will no longer add individual client public keys to the servers `authorized_keys` file. Now we will configure the server to use the CA public key to verify clients, and add the client certificate to the client to present to the server.

```
./init.sh
docker compose up -d --build
docker compose run client
```
You'll see the agent loading the identity and the certificate:
```
Agent pid 8
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
Certificate added: /home/sshuser/.ssh/id_ed25519-cert.pub (laptop.mydomain.local)
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
