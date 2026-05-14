# HTB - Pterodactyl

---
## General Info
- OS: Linux
- Open ports: 22, 80, 443, 8080
- Running services: MariaDB:? (11.8.3), Pterodactyl panel:panelvhost80(1.11.10)
- Endpoints:
- VHosts: panel.pterodactyl.htb
- Auth:
- Pwnd date:

---
## Enumeration  

- Ran basic scans blah blah blah. 
- Interesting part comes here: there's a changelog file, which mistakenly gives me the versions of all the frontend services. Version 1.11.10 of Pterodactyl panel is vulnerable to a RCE attack via [[CVE-2025-49132]], and there's a PoC. Trying that.
- Well wtf internet, wtf. This version is vulnerable to a Path Traversal attack, not a RCE attack. Lemme see if I can get anything useful out of this. I don't understand why everyone is calling this a RCE attack. This is not.
- 
  
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
  
  