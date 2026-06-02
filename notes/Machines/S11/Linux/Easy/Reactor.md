# HTB - Reactor

---
## General Info

- OS: Linux 6.8.0-117, Ubuntu 24.04.4 LTS
- Open ports: 22, 3000
- Running services: OpenSSH:22(9.6p1), NextJS:3000(15.0.3)
- Endpoints: -
- VHosts: -
- Auth: -
- Pwnd date: 28/5/2026

---
## OSINT

Dr. Elena Rodriguez
Lead Nuclear Engineer
ONLINE

Marcus Kim
Senior Technician
ONLINE

James Thompson
Safety Officer
OFFLINE

---
## Enumeration  

-  Ran nmap, and ffuf, but found nothing. 
-  Found, amongst all JS files, NextJS's version, which is compatible with the famous [[CVE-2025-55182 (R2S)]], which, as the name indicates, gives you a shell. I found a public [[Metasploit]] module, so I'll try that.
  
---
## Exploitation  

- Cool, I have a foothold as user *node*. Very cool, so I made some findings:
- There's a very suspicious script running as root, located in `/opt/uptime-monitor`, called worker.js. I'll keep that in mind for a next possible move. 
  
- More interestingly, after reading `/etc/passwd`, I found the user *engineer*. Does it sound similar to something? What about Dr. Elena Rodrigez? Interesting to associate a name to a user, even tho it could very possibly be a distraction. 
  
- Even MORE interestingly, I found these two values inside `env`:
	```env
	MEMORY_PRESSURE_WRITE=c29tZSAyMDAwMDAgMjAwMDAwMAA=
	SENSOR_API_KEY=rw_sk_7f8a9b2c3d4e5f6g7h8i9j0k
	```
- I still don't know what these are going to help with, but keeping it in mind.
- Oooookay. Well, look it up yourself:

```bash
root 1395 0.0 1.1 1066840 46964 ? Ssl 12:32 0:00 /usr/bin/node --inspect=127.0.0.1:9229 /opt/uptime-monitor/worker.js
```

- Remember that script? Well, root is running it with the --inspect flag. Which gives me a debugging js console with the privileges of the process. You get where I'm going? Starting PrivEsc.

---
## PrivEsc

- Followed the steps in [[Privilege Escalation - Common Library#Node.js --inspect debugger abuse|Node.js --inspect debugger abuse]]
- Got user flag.
- Got root flag.

---
## Rabbit holes

 - LOOOL. Both the env vars and the relation between user engineer and Dr. Elena Rodrigez.

---
## Attack chain

- Read the main page's JS to find NextJS version.
- Exploit [[CVE-2025-55182 (R2S)]] to get foothold as user *node*.
- Find file worker.js running as root with flag --inspect.
- Exploit the debug JS shell to get a shell as root, as indicated in [[Privilege Escalation - Common Library#Node.js --inspect debugger abuse|Node.js --inspect debugger abuse]]
- Get user flag
- Get root flag

---
## Learnt

- [[Privilege Escalation - Common Library#Node.js --inspect debugger abuse|Node.js --inspect debugger abuse]]
  
---
## Notes  
- Machine rating: Easy
  
  