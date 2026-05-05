# HTB - Silentium

---
## General Info

- OS: Linux
- Hostname: silentium.htb
- Open ports: 22, 80
- Running services: nginx 1.24.0, Flowise 3.0.5, [[SSH (Secure Shell)]] 9.6p1
- Endpoints: 
	- /assets
	
- VHosts: staging.silentium.htb
	- Endpoints:
		-  /api/v1
			- /settings
			- /loginmethod
			- /account
				- /forgot-password
			- /version
			- /node-load-method
				- /customMCP
		- /manifest.json
- Auth: Part of flowise.
- Pwnd date: 24/04/2026

---
## Enumeration  

-  Ran [[Nmap]]. Gave back port 22 and 80 running [[SSH (Secure Shell)]] and nginx
-  Opened the webpage. Nothing interesting.
-  Fuzzed the main page using [[FFuF]] got /assets/
-  Fuzzed VHosts using [[FFuF]]  and found staging.silentium.htb, running Flowise 3.0.5
-  Tried to access /api/v1/version and retrieved the Flowise Version: 3.0.5. 

---
## Exploitation  

-  Searched for known CVEs of Flowise, found a list of them but all of them required auth, except [[CVE-2025-58434|Auth bypass]].

---
At this point, I got lost, read a walkthrough and realized I'm fucking dumb and that a person named Ben was listed in the main page. 

### Learnt: *I should look more carefully in the next machine when looking for users and or creds.*

That name gave me the email ben@silentium.htb, which I then used with the CVE.

---

- Exploiting [[CVE-2025-58434|Auth bypass]] consisted of making a reset password request, **THAT REQUIRED A VALID USER'S EMAIL**, and it made the API endpoint return a temporary token. Using it, I changed ben's account password.  I was inside Flowise.
- After much trouble, found [[CVE-2025-59528|Flowise RCE]] and got a reverse shell inside the docker container (check CVE note for more reference).

---

I went back to the walktrhough after **too much time** wandering in the docker container. I got access to enviroment variables, using ```cat /proc/1/environ | tr '\0' '\n'```, which leaked a password. More info about this command in [[Reading env vars from proc#Why it works]].

Got [[SSH (Secure Shell)]] access to Ben's user, under the reutilized password "r04D!!_R4ge".

### Learnt: How to read env vars from proc using 
![[Reading env vars from proc#Command]]

---
## PrivEsc

- Executed LinPeas

---
## What the fuck is this machine. What in the actual world. 

 I had to search in the walkthrough. Again. For the third time. This whole machine had been insane, but PrivEsc exploits [[CVE-2025-8110|Gogs exploit]] which is even madder. Read the doc for further explaination, but tbh? I don't even understand it myself. Good luck.

### Learnt: Idfk. Check Gogs running on when PrivEsc 127.0.0.1:3001
 
---
## PrivEsc

- I don't even know mate. I don't even know. 
- Exploited [[CVE-2025-8110|Gogs exploit]] to get root access with [[CVE-2025-8110#PoC|Proof of concept script]], and retrieved root flag. Machine pwned.

---
## Notes  

- Machine rating: HARD