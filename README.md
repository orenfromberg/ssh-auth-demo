# ssh-auth-demo

This repo contains an exploration of various SSH authentication schemes that include:
* password authentication
* ssh client key authentication
* ssh client/server key authentication
* CA host certificate authentication
* CA host/client certificate authentication

Heavily based on this blog post: https://jameshfisher.com/2018/03/16/how-to-create-an-ssh-certificate-authority/

You will need docker and docker-compose to run these examples.

## 1-password-auth

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

The ssh client found a host named `server.mydomain.local` at ip `192.168.224.3` but it has no way to verify that it is who it says it is. Any server on the network could pretend to be the host named `server.mydomain.local`. This kind of attack is called a man in the middle (MitM) attack. Is this the real server that we are connecting to?

The server provided a hint in the form of an ssh key fingerprint. This unique identifier is derived from the public key used by the ssh serverand is used to verify the identity of the server. If it looks familiar then it is safe to trust the host.

In practice one should verify the identity of the server using a trusted third party, like from a system administrator or a website that publishes the public key fingerprint. For example, GitHub publishes the fingerprints [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).

The ssh client prompts the user to choose whether they want to trust that it is connecting to the real server. This authentication scheme is called Trust On First Use (TOFU). If we say no then the client will accept that the host key verification was a failure and exit. 

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

## 2-password-no-tofu

This example is identical to the first except we use ssh-keyscan ahead of time to add the server to our known hosts so that it is already trusted before we connect to it.

./init.sh

now do the following in the console:

```
sshuser@laptop:~$ mkdir -p ~/.ssh && chmod 700 ~/.ssh
sshuser@laptop:~$ ssh-keyscan server.mydomain.local > ~/.ssh/known_hosts
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
sshuser@laptop:~$ ssh server.mydomain.local
sshuser@server.mydomain.local's password: 
Linux server.mydomain.local 5.15.0-79-generic #86-Ubuntu SMP Mon Jul 10 16:07:21 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```


## 3-key-auth

The next step is to disable password authentication on the server and using a client SSH key for authentication instead.

To disable password authentication, add the following line to the server ssh configuration file `/etc/ssh/sshd_config`:

    PasswordAuthentication no

On the client we create an ssh key pair that consist of private and public keys.

The public key is then copied to the server.

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
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
# server.mydomain.local:22 SSH-2.0-OpenSSH_9.2p1 Debian-2
Agent pid 9
Enter passphrase for /home/sshuser/.ssh/id_ed25519:
```
The output is from scanning the server for the public keys and starting the ssh agent. Now we need to enter the passphrase for the private key `keypass`:

``` 
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
sshuser@laptop:/$
```

Once the private key is unlocked it is added as an identity to the SSH agent.

Now ssh into the server using `ssh server.mydomain.local`:

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

clean up:
1. exit the server
2. exit the client
3. run `docker compose down`

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
