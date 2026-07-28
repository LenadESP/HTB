# HTB - Bedside

---
## General Info
- OS: Linux, debian 13
- Open ports: 80, 22, 3000(filtered)
- Running services: Apache:80(2.4.68), OpenSSH:22(10.0p2)
- Endpoints: 
	- /javascript
	- /server-status
- VHosts: research.bedside.htb
- Auth: -
- Pwnd date:

---
## Enumeration  

- Ran nmap whatever you already know this shit.
- Okay. So. the main portal is empty as fuck. Fuzz found me basically nothing, and server status gives 403. But. There's an interesting thing in the research panel, a file upload panel, that only accepts certain files. Well. Supposedly. I changed the MIME header (aka magic bytes) of a WAV file, to be a PDF file, and guess? It accepted it. Moreover, while I was tampering with it, it printed an error that's very interesting. Basically, MIME type wrong blah blah blah AND unable to upload to */var/www/research.bedside.htb/uploads*. Whoops. Now I know where those files go. Let's see if I'm able to get anything interesting here. Also, the main index is written in php, so in case of a reverse shell I need to use a php one.
  
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
  
  