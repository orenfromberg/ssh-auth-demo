# host-cert-demo

the client will use key auth but the server will use a host cert to authenticate to the client.

this will help in the situation where you have many servers to authenticate with a client.

## set up server

start up the server with
```
docker compose build
docker compose run server
```

then start sshd with
```
/usr/sbin/sshd -D &
```

output a public key for the server that we want to sign:
```
root@server:~# cat /etc/ssh/ssh_host_ed25519_key.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/g7eioBEXNMC4qIL2H0mMIc/YOVJThvs5GxsmBb6LI root@server.mydomain.local
root@server:/# 
```

## set up CA

in another terminal, start the certificate authority:
```
docker compose run ca
```

create the ca key pair with password `keypass`:
```
root@ca:~# ssh-keygen -t ed25519 -N 'keypass' -C 'ca@mydomain.local'
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519): 
Created directory '/root/.ssh'.
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:DVkBnZJur5rK9+O6jI+JlZr0pYQVY2yLB3ttHhBv0FM ca@mydomain.local
The key's randomart image is:
+--[ED25519 256]--+
|    o. .E+oo     |
|   . +o ooo      |
|  . B ooo.       |
|   * B  oo       |
|  o = +.S..      |
|   = + .  .      |
|  o + o  .       |
| . O B..o        |
|  + O+B*o.       |
+----[SHA256]-----+
root@ca:~# 
```

start the agent and add the key to the agent:
```
root@ca:~# eval $(ssh-agent) && ssh-add
Agent pid 9
Enter passphrase for /root/.ssh/id_ed25519: 
Identity added: /root/.ssh/id_ed25519 (ca@mydomain.local)
root@ca:~#
```

copy the server public key to the CA:
```
root@ca:/# cat <<EOF > ~/server.mydomain.local.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/g7eioBEXNMC4qIL2H0mMIc/YOVJThvs5GxsmBb6LI root@server.mydomain.local
> EOF
```

create the host certificate for the server:

```
root@ca:~# ssh-keygen -s ~/.ssh/id_ed25519 -h -I server.mydomain.local -n server.mydomain.local server.mydomain.local.pub
Enter passphrase: 
Signed host key server.mydomain.local-cert.pub: id "server.mydomain.local" serial 0 for server.mydomain.local valid forever
root@ca:~#
```

Inspect the cert and note the principal. this means that only this host can use this certificate.
```
root@ca:~# ssh-keygen -L -f server.mydomain.local-cert.pub 
server.mydomain.local-cert.pub:
        Type: ssh-ed25519-cert-v01@openssh.com host certificate
        Public key: ED25519-CERT SHA256:z0p1U4/go2t/cq3H7z3fxC5qfGzcc57g+w642kXouvQ
        Signing CA: ED25519 SHA256:DVkBnZJur5rK9+O6jI+JlZr0pYQVY2yLB3ttHhBv0FM (using ssh-ed25519)
        Key ID: "server.mydomain.local"
        Serial: 0
        Valid: forever
        Principals: 
                server.mydomain.local
        Critical Options: (none)
        Extensions: (none)
root@ca:~# cat server.mydomain.local-cert.pub 
ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAICYodVEmqk8Z28SqMRJA8QAGw9lACNzrbBQGt5TLd+TdAAAAIHVRHiPkSYA3zDsFGc6eCmhFO90PxjvYh3F0PbrtdGALAAAAAAAAAAAAAAACAAAAFXNlcnZlci5teWRvbWFpbi5sb2NhbAAAABkAAAAVc2VydmVyLm15ZG9tYWluLmxvY2FsAAAAAAAAAAD//////////wAAAAAAAAAAAAAAAAAAADMAAAALc3NoLWVkMjU1MTkAAAAgSBgX9u/X17IO6tv4Olhqor/8DrRwaq5PC7sqtJnXQtoAAABTAAAAC3NzaC1lZDI1NTE5AAAAQGbrHp8y+yVGmHE/aiLLVteXd3bquQU5KTCHUmiH0X7TIvN6McnXgL9+O66vfC/jsw0BeqOGAuW1+zY6rYHYZAU= root@server.mydomain.local
root@ca:~# 
```

output the CA public key:
```
root@ca:~# cat ~/.ssh/id_ed25519.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgYF/bv19eyDurb+DpYaqK//A60cGquTwu7KrSZ10La ca@mydomain.local
root@ca:~# 
```

# set up client

in another terminal, start the client:
```
docker compose run client
```

create an ssh keypair:
```
ssh-keygen -t ed25519 -N 'keypass' -C sshuser@laptop.mydomain.local
```

copy the ca public key to the client and add the host cert to the known_hosts file:
```
cat <<EOF > ~/ca.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINk+f52wXWEY2X1s+uE6V+qjvemVSdhH/9WHT1sjgqYk ca@mydomain.local
> EOF
cat <<EOF > ~/.ssh/known_hosts
@cert-authority *.mydomain.local $(cat ~/ca.pub)
EOF
```

inspect the `known_hosts` file:
```
sshuser@laptop:~/.ssh$ cat known_hosts 
@cert-authority *.mydomain.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgYF/bv19eyDurb+DpYaqK//A60cGquTwu7KrSZ10La ca@mydomain.local
sshuser@laptop:~/.ssh$
```

## configure the server to use the host certificate

now go back to the server and copy the host cert there, configure and restart sshd:
```
root@server:/# cat <<EOF > /etc/ssh/ssh_host_ed25519_key-cert.pub
> ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAICYodVEmqk8Z28SqMRJA8QAGw9lACNzrbBQGt5TLd+TdAAAAIHVRHiPkSYA3zDsFGc6eCmhFO90PxjvYh3F0PbrtdGALAAAAAAAAAAAAAAACAAAAFXNlcnZlci5teWRvbWFpbi5sb2NhbAAAABkAAAAVc2VydmVyLm15ZG9tYWluLmxvY2FsAAAAAAAAAAD//////////wAAAAAAAAAAAAAAAAAAADMAAAALc3NoLWVkMjU1MTkAAAAgSBgX9u/X17IO6tv4Olhqor/8DrRwaq5PC7sqtJnXQtoAAABTAAAAC3NzaC1lZDI1NTE5AAAAQGbrHp8y+yVGmHE/aiLLVteXd3bquQU5KTCHUmiH0X7TIvN6McnXgL9+O66vfC/jsw0BeqOGAuW1+zY6rYHYZAU= root@server.mydomain.local
> EOF
root@server:/# echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" >> /etc/ssh/sshd_config
root@server:/# fg  
/usr/sbin/sshd -D
^C
root@server:/# /usr/sbin/sshd -D &
[1] 24
```

## copy the clients public key to the server

now go back to the client and copy they public key to the server using the `sshuser` password:
```
sshuser@laptop:~$ ssh-copy-id server.mydomain.local
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sshuser@server.mydomain.local's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'server.mydomain.local'"
and check to make sure that only the key(s) you wanted were added.

sshuser@laptop:~$ 
```

inspect that the key has been added on the server:
```
sshuser@server:~$ cat .ssh/authorized_keys 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC5im1QVhOzjXQNLBKYic84f/cuUtSuUZGiNMDIkn3di sshuser@laptop.mydomain.local
sshuser@server:~$
```

ssh to the server:
```
sshuser@laptop:~$ ssh server.mydomain.local
Linux server.mydomain.local 5.15.0-79-generic #86-Ubuntu SMP Mon Jul 10 16:07:21 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```

exit the server
exit the client
docker compose down