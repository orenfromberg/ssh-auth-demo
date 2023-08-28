# host-user-cert-demo

In this demo the client and server will authenticate with each other using certificates. The client will use a user certificate and the server will use a host certificate.

## set up server

1. start up the server with
```
docker compose build
docker compose run server
```

when the server starts up it will generate new host keys and then give you a command prompt:
```
ssh-keygen: generating new host keys: RSA ECDSA ED25519 
root@server:/# /usr/sbin/sshd -D &
[1] 9
root@server:/# 
```

2. Start sshd in the background. Later we'll need to bring it to the foreground to restart:
```
/usr/sbin/sshd -D &
```

3. Inspect a server public key that we will want to sign with the certificate authority. I like to use ed25519 because it is strong and fast:
```
root@server:~# cat /etc/ssh/ssh_host_ed25519_key.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/g7eioBEXNMC4qIL2H0mMIc/YOVJThvs5GxsmBb6LI root@server.mydomain.local
root@server:/# 
```

## set up Client

1. in another terminal, start the client:
```
docker compose run client
```

2. create an ssh keypair:
```
ssh-keygen -t ed25519 -N 'keypass' -C sshuser@laptop.mydomain.local
```

3. output the public key
```
sshuser@laptop:/$ cat ~/.ssh/id_ed25519.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSIzSwYaWsBjFOOmmQPI/6heNrrM0gO3SoouLwChsxj sshuser@laptop.mydomain.local
sshuser@laptop:/$ 
```

## set up CA

1. in another terminal, start the certificate authority:
```
docker compose run ca
```

2. create the ca key pair with password `keypass`:
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

3. start the agent and add the key to the agent:
```
root@ca:~# eval $(ssh-agent) && ssh-add
Agent pid 9
Enter passphrase for /root/.ssh/id_ed25519: 
Identity added: /root/.ssh/id_ed25519 (ca@mydomain.local)
root@ca:~#
```

4. copy the client public key to the CA:
```
root@ca:~# cat <<EOF > ~/client.mydomain.local.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSIzSwYaWsBjFOOmmQPI/6heNrrM0gO3SoouLwChsxj sshuser@laptop.mydomain.local
> EOF
```

5. copy the server public key to the CA:
```
root@ca:/# cat <<EOF > ~/server.mydomain.local.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/g7eioBEXNMC4qIL2H0mMIc/YOVJThvs5GxsmBb6LI root@server.mydomain.local
> EOF
```

6. create the user certificate for the client:
```
root@ca:~# ssh-keygen -s ~/.ssh/id_ed25519 -I laptop.mydomain.local -n sshuser client.mydomain.local.pub 
Enter passphrase: 
Signed user key client.mydomain.local-cert.pub: id "laptop.mydomain.local" serial 0 for sshuser valid forever
root@ca:~# 
```

7. create the host certificate for the server:

```
root@ca:~# ssh-keygen -s ~/.ssh/id_ed25519 -h -I server.mydomain.local -n server.mydomain.local server.mydomain.local.pub
Enter passphrase: 
Signed host key server.mydomain.local-cert.pub: id "server.mydomain.local" serial 0 for server.mydomain.local valid forever
root@ca:~#
```

8. Inspect the certs and note the principals.
```
root@ca:~# ssh-keygen -L -f server.mydomain.local-cert.pub 
server.mydomain.local-cert.pub:
        Type: ssh-ed25519-cert-v01@openssh.com host certificate
        Public key: ED25519-CERT SHA256:rMoLGq3/SaE+a1/v5yG++eDhkncEVTJ+FKKyNB6T1lQ
        Signing CA: ED25519 SHA256:Ze/ZU26sGy3yo+7QlfVwcLHG4SSOZaQqHQoIQDTHeB4 (using ssh-ed25519)
        Key ID: "server.mydomain.local"
        Serial: 0
        Valid: forever
        Principals: 
                server.mydomain.local
        Critical Options: (none)
        Extensions: (none)
root@ca:~# ssh-keygen -L -f client.mydomain.local-cert.pub 
client.mydomain.local-cert.pub:
        Type: ssh-ed25519-cert-v01@openssh.com user certificate
        Public key: ED25519-CERT SHA256:SaNYIDcm170n/VExgs0VGGC0+baKTtjCJIsIy6oIvuc
        Signing CA: ED25519 SHA256:Ze/ZU26sGy3yo+7QlfVwcLHG4SSOZaQqHQoIQDTHeB4 (using ssh-ed25519)
        Key ID: "laptop.mydomain.local"
        Serial: 0
        Valid: forever
        Principals: 
                sshuser
        Critical Options: (none)
        Extensions: 
                permit-X11-forwarding
                permit-agent-forwarding
                permit-port-forwarding
                permit-pty
                permit-user-rc
```

9. output the CA public key:
```
root@ca:~# cat ~/.ssh/id_ed25519.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgYF/bv19eyDurb+DpYaqK//A60cGquTwu7KrSZ10La ca@mydomain.local
root@ca:~# 
```

10. output the user and host certificates:
```
root@ca:~# cat client.mydomain.local-cert.pub 
ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAIKHBqCjK8aF/t8GasiItvDkNJErWMSJzAMQXyqfkGsfpAAAAIJSIzSwYaWsBjFOOmmQPI/6heNrrM0gO3SoouLwChsxjAAAAAAAAAAAAAAABAAAAFWxhcHRvcC5teWRvbWFpbi5sb2NhbAAAAAsAAAAHc3NodXNlcgAAAAAAAAAA//////////8AAAAAAAAAggAAABVwZXJtaXQtWDExLWZvcndhcmRpbmcAAAAAAAAAF3Blcm1pdC1hZ2VudC1mb3J3YXJkaW5nAAAAAAAAABZwZXJtaXQtcG9ydC1mb3J3YXJkaW5nAAAAAAAAAApwZXJtaXQtcHR5AAAAAAAAAA5wZXJtaXQtdXNlci1yYwAAAAAAAAAAAAAAMwAAAAtzc2gtZWQyNTUxOQAAACCWGy4Gq0CYiZ04Lswl2zM76dIxXVLRzJkbU7p5nJXakAAAAFMAAAALc3NoLWVkMjU1MTkAAABASfuCVwdEbDrdXMf/GUg40JU/GQ0mBbwY4BhBdCbVeFtFV4/WsyrZetXkxe3fvfjo375u1QbmgRiArNKkPX9gAQ== sshuser@laptop.mydomain.local
root@ca:~# cat server.mydomain.local-cert.pub 
ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAIEtAB7B8o5c0gGgM1CocIEcPJcrtdcSqXu6vITYhT9DkAAAAID8T1qABpzDXP1K4aRc6UgyQQZVHhflvYkIwexV2O9eoAAAAAAAAAAAAAAACAAAAFXNlcnZlci5teWRvbWFpbi5sb2NhbAAAABkAAAAVc2VydmVyLm15ZG9tYWluLmxvY2FsAAAAAAAAAAD//////////wAAAAAAAAAAAAAAAAAAADMAAAALc3NoLWVkMjU1MTkAAAAglhsuBqtAmImdOC7MJdszO+nSMV1S0cyZG1O6eZyV2pAAAABTAAAAC3NzaC1lZDI1NTE5AAAAQEC+ZIsEma8jnM1fzS+bQ/co+SHjYkgDXCQ55LOUu6AkQ0p1JiFPzYykyPyxlEJUVdRCGDBAKrfejJYGZpyz1wY= root@server.mydomain.local
root@ca:~# 
```

# back to the client

1. copy the ca public key to the client and add the host cert to the known_hosts file:
```
sshuser@laptop:/$ cat <<EOF > ~/ca.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYbLgarQJiJnTguzCXbMzvp0jFdUtHMmRtTunmcldqQ ca@mydomain.local
> EOF
sshuser@laptop:/$ cat <<EOF > ~/.ssh/known_hosts
@cert-authority *.mydomain.local $(cat ~/ca.pub)
EOF
sshuser@laptop:/$
```

2. inspect the `known_hosts` file:
```
sshuser@laptop:/$ cat ~/.ssh/known_hosts 
@cert-authority *.mydomain.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYbLgarQJiJnTguzCXbMzvp0jFdUtHMmRtTunmcldqQ ca@mydomain.local
sshuser@laptop:/$ 
```

3. copy the user certificate to the client:
```
sshuser@laptop:/$ cat <<EOF > ~/.ssh/id_ed25519-cert.pub
> ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAIKHBqCjK8aF/t8GasiItvDkNJErWMSJzAMQXyqfkGsfpAAAAIJSIzSwYaWsBjFOOmmQPI/6heNrrM0gO3SoouLwChsxjAAAAAAAAAAAAAAABAAAAFWxhcHRvcC5teWRvbWFpbi5sb2NhbAAAAAsAAAAHc3NodXNlcgAAAAAAAAAA//////////8AAAAAAAAAggAAABVwZXJtaXQtWDExLWZvcndhcmRpbmcAAAAAAAAAF3Blcm1pdC1hZ2VudC1mb3J3YXJkaW5nAAAAAAAAABZwZXJtaXQtcG9ydC1mb3J3YXJkaW5nAAAAAAAAAApwZXJtaXQtcHR5AAAAAAAAAA5wZXJtaXQtdXNlci1yYwAAAAAAAAAAAAAAMwAAAAtzc2gtZWQyNTUxOQAAACCWGy4Gq0CYiZ04Lswl2zM76dIxXVLRzJkbU7p5nJXakAAAAFMAAAALc3NoLWVkMjU1MTkAAABASfuCVwdEbDrdXMf/GUg40JU/GQ0mBbwY4BhBdCbVeFtFV4/WsyrZetXkxe3fvfjo375u1QbmgRiArNKkPX9gAQ== sshuser@laptop.mydomain.local
> EOF
sshuser@laptop:/$ 
```

4. add the certificate to the ssh-agent:
```
sshuser@laptop:/$ eval $(ssh-agent) && ssh-add
Agent pid 17
Enter passphrase for /home/sshuser/.ssh/id_ed25519: 
Identity added: /home/sshuser/.ssh/id_ed25519 (sshuser@laptop.mydomain.local)
Certificate added: /home/sshuser/.ssh/id_ed25519-cert.pub (laptop.mydomain.local)
sshuser@laptop:/$ 
```

## configure the server to use the host certificate

now go back to the server and copy the host cert there, configure and restart sshd:
```
root@server:/# cat <<EOF > /etc/ssh/ssh_host_ed25519_key-cert.pub
> ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAIEtAB7B8o5c0gGgM1CocIEcPJcrtdcSqXu6vITYhT9DkAAAAID8T1qABpzDXP1K4aRc6UgyQQZVHhflvYkIwexV2O9eoAAAAAAAAAAAAAAACAAAAFXNlcnZlci5teWRvbWFpbi5sb2NhbAAAABkAAAAVc2VydmVyLm15ZG9tYWluLmxvY2FsAAAAAAAAAAD//////////wAAAAAAAAAAAAAAAAAAADMAAAALc3NoLWVkMjU1MTkAAAAglhsuBqtAmImdOC7MJdszO+nSMV1S0cyZG1O6eZyV2pAAAABTAAAAC3NzaC1lZDI1NTE5AAAAQEC+ZIsEma8jnM1fzS+bQ/co+SHjYkgDXCQ55LOUu6AkQ0p1JiFPzYykyPyxlEJUVdRCGDBAKrfejJYGZpyz1wY= root@server.mydomain.local
> EOF
root@server:/# echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" >> /etc/ssh/sshd_config
```

copy the ca public key to the server and tell sshd to trust user certs signed by it.
```
root@server:/# cat <<EOF > /etc/ssh/ca.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYbLgarQJiJnTguzCXbMzvp0jFdUtHMmRtTunmcldqQ ca@mydomain.local
> EOF
root@server:/# echo "TrustedUserCAKeys /etc/ssh/ca.pub" >> /etc/ssh/sshd_config
```

Restart the SSH server:

```
root@server:/# fg
/usr/sbin/sshd -D
^C
root@server:/# /usr/sbin/sshd -D &
[1] 12
root@server:/# 
```

## ssh to the server

now go back to the client and ssh to the server:
```
sshuser@laptop:/$ ssh server.mydomain.local
Linux server.mydomain.local 5.15.0-79-generic #86-Ubuntu SMP Mon Jul 10 16:07:21 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@server:~$ 
```

# another server has appeared!

We will now create a host certificate for a new server and ssh into it from our laptop. This time the server is a pihole.

```
docker compose run pihole
```

Have the CA sign the public key of the pihole and put the cert on the server.

1. inspect the server public key of choice:
```
root@pihole:/# cat /etc/ssh/ssh_host_ed25519_key.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxgu1uWDNvfd8djGYbqaV6ehEZEP3xzMJroy8Oefxez root@pihole.mydomain.local
```
2. have the CA sign the public key
```
root@ca:~# cat <<EOF > ~/pihole.mydomain.local.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9IuNPQL8SxJ8dOj/j2LCr+x9MKyL5bTrx4LBt9z7UR root@pihole.mydomain.local
> EOF
root@ca:~# ssh-keygen -s ~/.ssh/id_ed25519 -h -I pihole.mydomain.local -n pihole.mydomain.local pihole.mydomain.local.pub
Enter passphrase: 
Signed host key pihole.mydomain.local-cert.pub: id "pihole.mydomain.local" serial 0 for pihole.mydomain.local valid forever
```

output the cert and the public key:

```
root@ca:~# cat pihole.mydomain.local-cert.pub 
ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAICEn7Y6gtcZbk1gFQAmymjDPe4MyUzOkQ+O+kqGTn4nzAAAAIB9IuNPQL8SxJ8dOj/j2LCr+x9MKyL5bTrx4LBt9z7URAAAAAAAAAAAAAAACAAAAFXBpaG9sZS5teWRvbWFpbi5sb2NhbAAAABkAAAAVcGlob2xlLm15ZG9tYWluLmxvY2FsAAAAAAAAAAD//////////wAAAAAAAAAAAAAAAAAAADMAAAALc3NoLWVkMjU1MTkAAAAglhsuBqtAmImdOC7MJdszO+nSMV1S0cyZG1O6eZyV2pAAAABTAAAAC3NzaC1lZDI1NTE5AAAAQOP9kN5XeIRg1btYS64ykv3TO98pLshl9E1cjuivN5AXZIHD91hf8hIDZjBqjzOPoy4vi1Z/xZfiTHlLiFbu9QM= root@pihole.mydomain.local
root@ca:~# cat ~/.ssh/id_ed25519.pub 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYbLgarQJiJnTguzCXbMzvp0jFdUtHMmRtTunmcldqQ ca@mydomain.local
```
3. copy the cert and public key to the pihole and start sshd
```
root@pihole:/# cat <<EOF > /etc/ssh/ssh_host_ed25519_key-cert.pub
> ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAICEn7Y6gtcZbk1gFQAmymjDPe4MyUzOkQ+O+kqGTn4nzAAAAIB9IuNPQL8SxJ8dOj/j2LCr+x9MKyL5bTrx4LBt9z7URAAAAAAAAAAAAAAACAAAAFXBpaG9sZS5teWRvbWFpbi5sb2NhbAAAABkAAAAVcGlob2xlLm15ZG9tYWluLmxvY2FsAAAAAAAAAAD//////////wAAAAAAAAAAAAAAAAAAADMAAAALc3NoLWVkMjU1MTkAAAAglhsuBqtAmImdOC7MJdszO+nSMV1S0cyZG1O6eZyV2pAAAABTAAAAC3NzaC1lZDI1NTE5AAAAQOP9kN5XeIRg1btYS64ykv3TO98pLshl9E1cjuivN5AXZIHD91hf8hIDZjBqjzOPoy4vi1Z/xZfiTHlLiFbu9QM= root@pihole.mydomain.local
> EOF
root@pihole:/# cat <<EOF > /etc/ssh/ca.pub
> ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYbLgarQJiJnTguzCXbMzvp0jFdUtHMmRtTunmcldqQ ca@mydomain.local
> EOF
root@pihole:/# echo "TrustedUserCAKeys /etc/ssh/ca.pub" >> /etc/ssh/sshd_config
root@pihole:/# echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" >> /etc/ssh/sshd_config
root@pihole:/# /usr/sbin/sshd -D &
[1] 12

```
4. ssh to the server
```
sshuser@laptop:/$ ssh pihole.mydomain.local
Linux pihole.mydomain.local 5.15.0-79-generic #86-Ubuntu SMP Mon Jul 10 16:07:21 UTC 2023 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
sshuser@pihole:~$
```

a bit easier?