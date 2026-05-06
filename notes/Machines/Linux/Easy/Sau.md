# HTB - Sau

---
## General Info
- OS: Linux
- Open ports: 22, 55555
	- Filered (firewall): 80, 8338
- Running services: [[SSH (Secure Shell)|SSH:22]] (8.2p1), [Request-baskets:55555](https://github.com/darklynx/request-baskets)(1.2.1), [Maltrail:80](https://github.com/stamparm/maltrail) (v0.53)
- Endpoints (on 55555):
	- /web
- VHosts: -
- Auth: -
- Pwnd date: 06/05/2026

---
## Enumeration  

- Noticed that curling to the default port (80) didn't give an answer. [[Nmap|Nmapped]] the host on my own, and didn't use [[Enum.sh]]. 
- Found several ports, including 55555, which runs request-baskets (a functionallity/service to collect and register requests on a specific route). 
- Searched online, and found that the service has a known [[SSRF (Server-Side Request Forgery)|SSRF]] [[CVE-2023-27163]] with a [[CVE-2023-27163#PoCscript|PoC]]. Trying that. 

---
## Exploitation  

- Okay so I had to modify the PoC quite a bit (because it was made to run on a local docker environment) but basically what this does is that, if you make it request localhost services, you get a proxy like thing. Enumerating local services.
- Found Maltrail in port 80, running on a old version. The [[SSRF (Server-Side Request Forgery)|SSRF]] [[CVE-2023-27163#PoC|PoC]] actually lets you proxy a service to a basket, which is what I did. Now I have public access to MalTrail.
- Found a known RCE CVE (no known common CVE code) with a [PoC](https://github.com/spookier/Maltrail-v0.53-Exploit), trying that to get a reverse shell.
- Got a shell as user *puma*
- I upgraded the shell following [[Reverse Shell#Upgrade shell|Upgrade shell]], .
- Got user flag. Starting PrivEsc.

---
## PrivEsc

-  Followed steps written in [[Privilege Escalation - Common Library#Sudo pager escape|Sudo pager escape]] after realizing I had the following critical permission, listed using `sudo -l` which gives back commands I can execute as root:
  `NOPASSWD: /usr/bin/systemctl status trail.service`

---
## Rabbit holes

 -  Went down a 20 minute rabbithole trying to break `NOPASSWD: /usr/bin/systemctl status trail.service` sudo executable permission.
 - Well it wasn't a rabbit hole. I then proceeded to went down a half an hour rabbit hole trying to search something else, when the real vuln was the one described here: [[Privilege Escalation - Common Library#Sudo pager escape|Sudo pager escape]]

---
## Attack chain

- Discover Request-buckets in port 55555, and exploit it to proxy to a local service, called MalTrail.
- Exploit MalTrail RCE CVE and get a reverse shell.
- Get user flag.
- List sudo execution using `sudo -l`, and discover critical `NOPASSWD: /usr/bin/systemctl status trail.service` permission.
- Exploit the PrivEsc path descrived in [[Privilege Escalation - Common Library#Sudo pager escape|Sudo pager escape]].
- Get root flag. 

---
## Learnt
- Another way to PrivEsc. [[Privilege Escalation - Common Library#Sudo pager escape]]
  
---
## Notes  
- Machine rating: Very Easy