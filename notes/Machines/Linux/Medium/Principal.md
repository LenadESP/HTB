# HTB - Principal

---
## General Info

- OS: Linux
- Open ports: 22, 8080
- Running services: ssh, Jetty
- Endpoints: 
	- /api
		- /auth/jwks
		- /dashboard
		- /users
		- /settings
	- /dashboard
	- /login
	- /error (500)
	- /web-inf (500)
- Auth
	- [[Jetty]] + [[pac4j (-jwt)]]
	- Auth = [[JWT, JWE, JWKS]] (JWE)
	- Public key exposed at `/api/auth/jwks`
	- Roles enforced server-side (`ROLE_ADMIN`, etc.)
- Pwnd date: 23/04/2026

---
## Enumeration  

1. Ran nmap, found port 22 and 8080 running ssh and jetty.
2. Opened the web, went to source code and retrieved frontend JS
3. Found [[JWT, JWE, JWKS]] endpoint exposed in /api/auth/jwks bya frontend JS
4. Fuzzed page using [[FFuF]].
5. Robots.txt doesn't exist or isn't accesible.

---
## Exploitation   

1. Found [[CVE-2026-29000]]  on pac4j-jwt version 6.0.3 
2. Forged token and access /dashboard
3. Retrieved user.json and settings.json from API
   
---

At this point, I got lost and read the walkthrough.
Turns out that in the dashboard, there's the private JWS key (in plaintext) under the /settings endpoint.
At first, I assumed (correctly) that this was the JWS private key, but turns out that you can reuse that key to access **SSH** under the "svc-deploy" user.
### LEARNT: ALWAYS TRY TO REUSE CREDS

---

Got access to svc-deploy user using the JWS private key, which was a password, ```D3pl0y_$$H_Now42```, and got user.flag. Starting PrivEsc.

---
## PrivEsc  

- Check svc-deploy user's group: deployers. [[HELPFUL COMMANDS]]
- Checked what folders the group deployers could read:
	- /opt/principal/ssh
- Retrieved CA key from mentioned path.
- Used hint in task 10 (doing guided mode). Searched for ssh config location, found ```/etc/ssh/sshd_config.d/60-principal.conf``` with custom config for user principal. 

---

I got lost again. 
I read the walkthrough, and learnt about [[SSH (Secure Shell)#SSH Certificates (CA)|CA certfs]], and followed the exploitation path written in [[SSH (Secure Shell)#Attack Steps]]
### LEARNT: CE certificates and how to exploit them

---
## Notes  

- /opt/principal gave me access to the whole page, including credentials for DBs and internal services.
- Machine rating: EASY