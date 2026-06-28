# HTB - Machine

---
## General Info
- OS: Linux, Ubuntu
- Open ports: 22, 80, 110, 111
- Running services: Nginx:80, Dovecot, NFS server, Roundcube:mailto001(1.6.16)
- Endpoints: -
- VHosts: mail001.enigma.htb
	- /plugins
- Auth: -
- Pwnd date:

---
## Enumeration  

- Ran basic enumeration (nmap, fuzzing, etc), and I got a whole list of fucking ports. Lemme tell ya, I know about 3 lol.
- Okay. So. We have some cool things. On the one side, we have a mail service running, on the other, a [[NFS (network file system)]] server.
- After mounting the exposed folder, I got a pdf with some default creds for new staff. Lemme say, they did in fact not change it as it says in the pdf. I have access to the Roundcube main panel. 
- I searched for known CVEs, but this panel is up to date, and there's only an email, with no interesting information.
  
---
## Exploitation  

-  

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
  
  