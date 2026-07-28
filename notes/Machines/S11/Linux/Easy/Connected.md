# S11 - Connected

---
## General Info
- OS: Linux
- Open ports: 22, 80, 443
- Running services: Apache:80(2.4.6), PHP:80(7.4.16), OpenSSL:443(1.0.2k)
- Endpoints: -
- VHosts: -
- Auth: -
- Pwnd date:

---
## Enumeration  

- Ran basics (nmap, ffuf, vhostffuf), found nothing interesting, and accessed main page. Functionality doesn't seem to change over https, so I'll stick to http for Burp access.
- Ok, interesting enough, I found FreePBX running on port 80, and after searching the version, I found [[CVE-2025-57819]], a RCE vuln, and a public PoC that has been uploaded to GitHub 20H ago LOOOOL someone has done this machine *(the example URL is http://connected.htb LOL)*. Let's see what this PoC gives me.
 
---
## Exploitation  

-  Okay we have a terminal as user *asterisk*, cool. Got user flag and starting PrivEsc.

---
## PrivEsc

-   

---
## Rabbit holes

 - 

---
## Attack chain

- 

---
## Learnt

- 
---
## Notes  
- Machine rating:
  
  