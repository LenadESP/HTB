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