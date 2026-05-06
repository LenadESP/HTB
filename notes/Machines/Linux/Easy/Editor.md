# HTB - Editor

---
## General Info

- OS: Linux
- Open ports: 22, 80, 8080
- Running services: [[SSH (Secure Shell)|SSH]](8.9p1), Nginx (1.18.0), Jetty 10.0.20, XWiki (15.10.8)
- Endpoints: editor.htb
- VHosts: wiki.editor.htb
- Auth: none
- Pwnd date: 05/05/2026

---
## Enumeration  

- Ran [[Enum.sh]], got back ports, no endpoints, and got vhost wiki.
- Went to wiki, and found XWiki version. Found a [[Reverse Shell]] [[CVE-2025-24893|CVE]]. Testing the [[CVE-2025-24893#PoC|PoC]] now. 

---
## Exploitation  

- Ran the [[CVE-2025-24893#PoC|PoC]] and got a reverse shell under user xwiki. /home shows user oliver, and permission is denied.
- After much digging around config files, I found the password to the mysql database, under user "xwiki" and password "theEd1t0rTeam99". Let's see if oliver reuses credentials. 
- `su oliver` with that password didn't let me in. I'll try to enter the DB to see if there's any credentials.
- Found a hash. Still don't know what user for. Let's try to crack it and see if it's oliver's.

---
### I hate HTB. I despite it with my whole life. Remember "theEd1t0rTeam99"? well. `su oliver` didn't accept it. SSH did. I'm deadass, yes. And I had to search a writeup. fuck.

# LEARNT: ALWAYS. AGAIN. ALWAYS REUSE CREDENTIAL IN, AND THIS IS IMPORTANT, IN ALL WAYS POSSIBLE AND ALL SERVICES AVAIABLE.

Got user flag. Starting PrivEsc

---
## PrivEsc

- Followed basic [[Privilege Escalation - Common Library#Generic|generic privesc]]
- Found that the user "oliver" is inside group oliver and netdata

> Ok I will explain everything a little bit. Basically, I found a some files with capacities and found a SUID binary I had ignored before. I could execute them, with the group "netdata". 
> I searched known attack vectors, and found that if you can change PATH, you can make that binary execute the file you want (it executes different plugins that it looks up in the path). We tried with an sh script, didn't work. With a compiled binary, also didn't. In the end, I looked up the writeup, and found that in C, if you want to keep the group, you need to do `setuid()` and `setgid()` respectively. 

This is recognized as [[CVE-2024-32019]].

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    setuid(0);
    setgid(0);
    system("/bin/bash");
    return 0;
}
```

>Note: replacing or copying /bin/bash didn't work, even when the file was SUID and owned by root (but still executable and writable by me, oliver). Spawning a shell did. Whatever. Kinda a weird PrivEsc tbh.

---
## Rabbit holes

 - Went down a rabbit hole searching for credentials in the database and trying to crack the has when I already had the MySQL credentials.

---
## Attack chain

- Exploit XWiki's [[CVE-2025-24893]] and get a [[Reverse Shell]].
- Find MySQL credentials inside XWiki's config and reuse them with [[SSH (Secure Shell)|SSH]] to get to Oliver user.
- Grab user flag.
- Exploit ndsudo's [[CVE-2024-32019]] using the [[CVE-2024-32019#PoC|PoC]] and spawn root shell.
- Grab root flag.

PWNED

---
## Notes  
- Machine rating: Easy