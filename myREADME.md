# Ex1
Initially when we try to GET a response from www.textfiles.com using curl we get the following:

```
vagrant@server1:~$ curl -v http://www.textfiles.com/art/bnbascii.txt
*   Trying 208.86.224.90:80...
* TCP_NODELAY set
* connect to 208.86.224.90 port 80 failed: No route to host
* Failed to connect to www.textfiles.com port 80: No route to host
* Closing connection 0
curl: (7) Failed to connect to www.textfiles.com port 80: No route to host
```
which tells us two things:
1. The DNS name is resolved to a proper IP address (208.86.224.90)
2. We can't connect to it and cURL does not provide too much information on why that is.

Looking at the bootstrap.sh script, i decoded the base64 string and noticed the following line:
```
ip route add 208.86.224.90/32   dev enp0s8 src 192.168.100.10
``` 

Googling for what this command does i found out it adds a routing rule to the kernel's routing table. in our case (if i understand it correctly) it redirects all traffic to 208.86.224.90 back to our server (192.168.100.10)
so to fix this i removed this routing rule with:
```
sudo ip route del 208.86.224.90
```

<br />

# Ex2
Initially when we run ```curl http://www.ascii-art.de/ascii/ab/007.txt``` we get the following response:

```
vagrant@server1:~$ curl -v http://www.ascii-art.de/ascii/ab/007.txt
*   Trying 127.0.0.1:80...
* TCP_NODELAY set
* Connected to www.ascii-art.de (127.0.0.1) port 80 (#0)
> GET /ascii/ab/007.txt HTTP/1.1
> Host: www.ascii-art.de
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 403 Forbidden
< Date: Sun, 25 Jul 2021 08:01:30 GMT
< Server: Apache/2.4.41 (Ubuntu)
< Content-Length: 281
< Content-Type: text/html; charset=iso-8859-1
<
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>403 Forbidden</title>
</head><body>
<h1>Forbidden</h1>
<p>You don't have permission to access this resource.</p>
<hr>
<address>Apache/2.4.41 (Ubuntu) Server at www.ascii-art.de Port 80</address>
</body></html>
* Connection #0 to host www.ascii-art.de left intact
```

we can see in the above output that the request was sent to the loopback ip (or to our own server1 basically) and the returned result was "403 Forbidden".
So again this is some routing issue. Looking again at the decoded bootstrap.sh we can see the following line which is the culprit:
```echo '127.0.0.1 www.ascii-art.de' >> /etc/hosts```

To resolve this i added the following command in the relevant file:
```
sudo sed -i '/www.ascii-art.de/d' /etc/hosts
```
This removed the line redirecting www.ascii-art.de calls to ourselves (removes the line in place). 

<br />

# Ex3
Initially when we log in to 192.168.100.10 we get the following:

>Forbidden
You don't have permission to access this resource.

>Apache/2.4.41 (Ubuntu) Server at 192.168.100.10 Port 80

Since we are running an apache web server on our server1 vm. this looks like some kind of permissions issue with the apache configuration itself.

Looking at /etc/apache2/sites-available/000-default.conf (tipped again by bootstrap.sh) we can see the following at the end of the file:

```
<Location "/">
  Require all denied
</Location>
```
which will deny all connections to our root path. 

> sites-avilable directory contains configurations for multi site serving (e.g. if you have several websites served from the same server and you need different configuration per site)

To fix this i added the following commands in exercise3-fix.sh:
```
sudo sed -i 's/Require all denied/Require all granted/g' /etc/apache2/sites-available/000-default.conf
sudo service apache2 reload
```
The first command replaced 'Require all denied' with 'Require all granted' in place in  /etc/apache2/sites-available/000-default.conf file.

The second command reloads the web server service so these changes can take affect.

<br />

# Ex4
Initially we can't ssh between our servers. To overcome this we need to generate ssh key-pair for permitting password less access. 

since server1 is provisioned before server2 we will run the following: 
```
ssh-keygen -t rsa -f /vagrant/id_rsa -q -N ''

cp /vagrant/id_rsa /home/vagrant/.ssh/

chown vagrant /home/vagrant/.ssh/id_rsa

cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
````

1. generate key pair in a shared folder from which we can later copy to both machines.
2. cp the private key file to $HOME/.ssh folder
3. since the keys were generated during provisioning as root we need to change the file's ownership for it to be used by vagrant user
4. lastly we append the public key to both machine's $HOME/.ssh/authorized_keys file to allow ssh using the same key and without password.

>Notes: 
>1. it would be a better practice to clean up the generated key files at the end of server2 provisioning
>2. it would probably be better to generate different key pairs per each machine. but this can be done either by using vagrant's built in ssh sharing mechanism or using vagrant triggers to run a relevant script once the machine is up. otherwise we have issues with copying server2 public key to server1 while server1 is being provisioned and server2 is not yet

<br />

# Ex5

Our previous solution for Ex4 alreday allows for password-less ssh connection between the servers. To configure no host-key checking we can set the following in the clients' ssh config files (~/.ssh.config):

>**StrictHostKeyChecking:** This option configures whether ssh SSH will ever automatically add hosts to the ~/.ssh/known_hosts file. By default, this will be set to “ask” meaning that it will warn you if the Host Key received from the remote server does not match the one found in the known_hosts file. If you are constantly connecting to a large number of ephemeral hosts, you may want to turn this to “no”. SSH will then automatically add any hosts to the file. This can have security implications, so think carefully before enabling it.
>
>**UserKnownHostsFile:** This option specifies the location where SSH will store the information about hosts it has connected to. Usually you do not have to worry about this setting, but you may wish to set this to /dev/null if you have turned off strict host checking above.

The contents of the config files will be:
```
Host server*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
```

<br />

# Ex6
The script is available in the relevant file.
It basically does the following:

1. Verify there are at least 2 arguments on the command line and parse the arguments.
2. Checks whether the user is root or not. if it is root - copies the ssh configuration and keys from the vagrant user home dir so these could be used to establish a seamless connection to the other server.
3. Checks the current host and set the target host accordingly so the same script can run on either serever.
4. Copy the relevant files using rsync command. I chose rsync over scp since it's verbose output is better suited for parsing the amount of bytes copied.
5. Print the amount of bytes copied.

I tested this both as vagrant user inside either servers, and also as root during provisioning (can provide a relevant vagrant file if required).

### GOOD LUCK TO ME.