# HTB - Down

---
## General Info
- OS: Linux
- Open ports: 22, 80
- Running services: Apache (2.4.52), OpenSSH (8.9p1)
- Endpoints: -
- VHosts: 
- Auth:
- Pwnd date:

---
## Enumeration  

- Ran nmap and endpoint discovery. (It doesn't redirect to a hostname so I ommited VHost discovery)
- Went to the main page and saw that it takes a URL, requests it, and if it is up then prints the HTML, if it's not, then it prints "It is down :(". This smells a lot to [[SSRF (Server-Side Request Forgery)]], so I'll craft a script to probe against all ports in localhost (it does answer when localhost requested, so I'm guessing there's no sanitization).
  
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
  
  