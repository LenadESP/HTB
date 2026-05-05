# HTB - Wing Data

---
## General Info

- OS: Linux
- Open ports: 80, 22
- Running services: Apache 2.4.66, SSH 9.2p1, Wing FTP 7.4.3
- Endpoints: Not
- VHosts: ftp.wingdata.htb
- Auth: Basically none
- Pwnd date: 04/05/2026

---
## Enumeration  

- Ran [[Nmap]].
- Found vhost fpt.wingdata.htb (the client portal redirects there), running Wing FTP version 7.4.3, that has a RCE [[CVE-2025-47812]], I'm gonna try to exploit it (doens't seem to require auth).

---
## Exploitation

-  Yup. [[CVE-2025-47812]] PoC gave me command execution under the user "wingftp". I'll try to get a reverse shell, to stabilize it.
- Got a reverse shell, using [[Reverse Shell#Netcat (if supported)|NetCat RS]], and then stabilized it by using [[Reverse Shell#Upgrade shell|Upgrading shell]].
- Got user flag, starting PrivEsc. (15 minutes go by) Well, no, actually.
- The RS got me into the user "wingftp", which does not have access to the flag. I'll start PrivEsc because I believe it to be possible to jump to root.

---
- Well this was very, very, very absolutely fucking dumb. I searched and enumerated the whole thing, and found the hash for users and admin, amongst other config files. I tried to modify the hash of admin, tried to log in into the admin webpanel (something impossible effectively without hours of tampering because it runs on localhost and ssh proxying was out of the way without wingftp user's password) etc.
- I went down a rabbit hole and had to search up a writeup. This part was the most basic thing I could've done. [[Hash cracking]]. That's what I missed. Fuck.
- Got the password for user "wacky" and got user flag. Also got [[SSH (Secure Shell)|SSH]] access reusing creds. Starting, once and for all, PrivEsc.
  
  ## LEARNT: DON'T GO DOWN RABBIT HOLES WITHOUT CHECKING THE OBVIOUS FIRST ¬_¬
---
## PrivEsc

-  Ok, after enumerating the machine a little more (why not), well actually trying to cd to a folder I was not enabled to cd before, I found a backup.py file, that was vulnerable to [[CVE-2025-4517]]. Trying PoC.
- Gave me root. Don't ask me how. Don't ask me why. Read [[CVE-2025-4517]] if you're brave enough. I guess I'll be a ScriptKiddie for a while. 
- Got root flag. 

---
## Notes  

- Machine rating: Medium