# HTB - Horizontall

---
## General Info

- OS: Linux
- Open ports: 22, 80
- Local ports: 3556, 8000
- Running services: Nginx:80(1.14.0), SSH:22 (7.6p1), Strappi (3.0.0-beta.17.4), Laravel:8000(<8.4.2)
- Endpoints:
    - /js
    - /css
    - /img
- VHosts: www, api-prod:
    - api-prod.horizontall.htb:
        - /admin/init
- Auth: - (lol)
- Pwnd date: 14/06/2026

---
## Enumeration

- Ran basic scans (nmap and ffuf for endpoints and VHosts), and found a vhost (`api-prod`) that runs Strapi version 3.0.0-beta.17.4 (found in /admin/init), which has two known CVEs.

- These two CVEs, when chained, lead to a RCE, which leads to a [[Reverse Shell]]. Executing the [chained PoC](https://github.com/glowbase/CVE-2019-19609)

---
## Exploitation

- Executed the [PoC](https://github.com/glowbase/CVE-2019-19609), got a reverse shell as user _strapi_, and upgraded it following [[Reverse Shell#Upgrade shell|RSUS]].
- Starting horizontal PrivEsc

---
## Horizontal PrivEsc

- After examining the home page of user _strapi_, I came across a configuration file found in `/opt/strapi/myapi/config/environments/development` (developtment because that's the "mode" the API is in, found in /admin/init from the API). This file contains some credentials I'll try to reuse or test in the localhost database:

```JSON
{
  "defaultConnection": "default",
  "connections": {
    "default": {
      "connector": "strapi-hook-bookshelf",
      "settings": {
        "client": "mysql",
        "database": "strapi",
        "host": "127.0.0.1",
        "port": 3306,
        "username": "developer",
        "password": "#J!:F9Zt2u"
      },
      "options": {}
    }
  }
}
```

- Ok so no SSH or su as _developer_, I'll use those credentials in the MySQL DB to see if I find anything meaningful.
- I'm inside the MySQL DB.
- Inside strapi/strapi_administrator, I found credentials for an admin:

```
admin
admin@horizontall.htb 
$2a$10$SNgaV2jFfCjDvp5d3Xmt5e3M8amxo5x9PIY3/U5quVlXbOVHXK4t. 
```

- Cracked password (`Password123`) but wasn't useful. I tried to reuse it everywhere and it didn't work. I'll finish enumerating MySQL DB and then pivot to the machine again.
- Nothing interesting in the DB (the app's schemas and the admin password, but there's no other user besides admin, nor other credentials I could reuse). I'll pivot to the machine.
- MOTHEFUCKERS. THAT'S. UGHHHHHHHHHHH. They hid processes running by other users, that's why I missed a whole service running: Laravel V8. Only localhost. There were 3 ports listening on LocalHost: port 1335, 8000, and 3556. 1335 is strapi, port 3556 is MySQL, and I wrongly assumed that port 8000 was the internal port of the main page, which Nginx (port 80 open) was proxying. Nope. Port 8000 is a whole new service running on localhost. I don't know which user runs it, but I'll poke it. I found an RCE vulnerability, so it's worth trying.

Oh. Just. Fuck.

```bash
strapi@horizontall:/etc/php/7.4$ ls -la /home/developer/
total 108
drwxr-xr-x  8 developer developer  4096 Aug  2  2021 .
drwxr-xr-x  3 root      root       4096 May 25  2021 ..
lrwxrwxrwx  1 root      root          9 Aug  2  2021 .bash_history -> /dev/null
-rw-r-----  1 developer developer   242 Jun  1  2021 .bash_logout
-rw-r-----  1 developer developer  3810 Jun  1  2021 .bashrc
drwx------  3 developer developer  4096 May 26  2021 .cache
-rw-rw----  1 developer developer 58460 May 26  2021 composer-setup.php
drwx------  5 developer developer  4096 Jun  1  2021 .config
drwx------  3 developer developer  4096 May 25  2021 .gnupg
drwxrwx---  3 developer developer  4096 May 25  2021 .local
drwx------ 12 developer developer  4096 May 26  2021 myproject
-rw-r-----  1 developer developer   807 Apr  4  2018 .profile
drwxrwx---  2 developer developer  4096 Jun  4  2021 .ssh
-r--r--r--  1 developer developer    33 May 13 10:06 user.txt
lrwxrwxrwx  1 root      root          9 Aug  2  2021 .viminfo -> /dev/null
strapi@horizontall:/etc/php/7.4$ cat /home/developer/user.txt
[REDACTED]
```

- What. The. Fuck. Whatever. Got user flag.
- Starting PrivEsc

---
## PrivEsc

- Once I realized that Lavarel V8 was running on localhost, I searched for known CVEs. I found [[CVE-2021-3129]], and without knowing what user it was being executed by (because remember, I couldn't see the processes owned by other users), I tried the PoC. The response was beautiful:

> Before the answer, is important to say that I was operating totally blind. I didn't know what to expect, or what user I'd get. But it was worth trying as I mentioned earlied. The part where I get the user flag was me trying to find where Laravel was at, and which user was owner of the process. While I was doing that, I noticed that /home/developer/user.txt had the permission bits -r--r--r, which means it's readable by anyone (and I got user flag). Then, I tried the PoC blindly. All I knew is that it could work. Well:

```bash
strapi@horizontall:/tmp$ python3 exploit2.py 
[*] Try to use monolog_rce1 for exploitation.
[+] PHPGGC found. Generating payload and deploy it to the target
[*] Result:
uid=0(root) gid=0(root) groups=0(root)
```

- After changing the exploit to make it run `chmod +s /bin/bash`, and executing `/bin/bash -p`, I got root.
- Got root flag.

---
## Rabbit holes

- Assumed port 8000 on localhost was the internal port Nginx was proxying to. It wasn't — it was a completely separate Laravel app. Cost me significant time.
- Tried SSH and `su` as _developer_ with the MySQL config creds. Nothing.
- Cracked Strapi admin hash (`Password123`), tried credential reuse everywhere. Nothing.
- First PoC (multi-chain exploit.py) returned empty results for all chains. Switched to a single-chain PoC (exploit2.py) which worked.

---
## Attack chain

- Vhost fuzzing → `api-prod.horizontall.htb`
- Fingerprint Strapi v3.0.0-beta.17.4 via `/admin/init`
- Chain CVE-2019-18818 + CVE-2019-19609 → RCE → reverse shell as _strapi_
- Find MySQL creds in `/opt/strapi/myapi/config/environments/development/database.json`
- Login to MySQL as _developer_, extract and crack Strapi admin hash → dead end
- Enumerate local ports with `ss -tlnp` → find Laravel on port 8000 (hidden by `hidepid=2`)
- Exploit [[CVE-2021-3129]] (Laravel debug mode RCE) via `/_ignition/execute-solution`
- RCE as root → `chmod +s /bin/bash` → `bash -p` → root
- Got root flag.

---
## Learnt

- `hidepid=2` hides other users' processes — see [[Privilege Escalation - Common Library#What is listening? What is running?]]
- Always curl every locally listening port. Never assume what's behind it.
- DNS wordlists find vhosts that web-content wordlists miss.

---
## Notes

- Machine rating: Easy ish going to medium.