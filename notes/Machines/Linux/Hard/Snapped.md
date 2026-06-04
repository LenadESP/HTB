# HTB - Snapped

---
## General Info
- OS: Linux snapped 6.17.0-19-generic #19~24.04.2-Ubuntu
- Open ports: 22, 80
- Running services: Nginx:80(1.24.0), NginxUI:80:admin(2.3.2)
- Endpoints: -
- VHosts: admin.snapped.htb
- Endpoints:
	- /assets
	- /mcp

/nodes: POST /nodes/reload_nginx, POST /nodes/restart_nginx, POST /nodes/load_from_settings
/users, /user, /user/password, /user/language
/2fa_status, /2fa_secure_session/otp, /2fa_secure_session/status, /2fa_secure_session/passkey
/crypto/public_key
/dns/domains and nested: /dns/domains/{domain}/records, /dns/domains/{domain}/ddns, /dns/ddns

- Auth: -
- Pwnd date: 04/06/2026

---
## Enumeration  

- Ran nmap, found port 80 redirecting to snapped.htb and port 22 open. I ran basic fuzzing on the main page and it showed nothing. After fuzzing for vhosts, I found admin.snapped.htb and fuzzed it again.
- Found version of NginxUI in a module of the main index.js, under a version-gibberish.js. Searching for known CVEs. 
- Okay, found [[CVE-2026-27944]], which dumps me a whole backup of the server.
  
---
## Exploitation  

- Managed to get the PoC working after much tampering with the help of Github Copilot, and now I have the app.ini, the DB and the whole config of Nginx. I'll search the DB.
- Found two hashes that I'll try to crack with hashcat:

```
1|2026-03-19 08:22:54.41011219-04:00|2026-03-19 08:39:11.562741743-04:00||admin|$2a$10$8YdBq4e.WeQn8gv9E0ehh.quy8D/4mXHHY4ALLMAzgFPTrIVltEvm|1||

2|2026-03-19 09:54:01.989628406-04:00|2026-03-19 09:54:01.989628406-04:00||jonathan|$2a$10$8M7JZSRLKdtJpx9YRUNTmODN.pKoBsoGCBi5Z8/WVGO2od9oCSyWq|1||
```
- They're BCrypt hashes, so I don't think I'll be able to crack them. I'll keep investigating further and will let hashcat run in the background just in case.
- Cracked jonathan's: `jonathan:parola`, but doesn't work on the page.
- I also have the JWT forging secret.
  
  # OH. OKAY. SURE. I went through the writeup because I had been banging my head against a wall for 2H and found out hashcat had trolled me. I sent the output to 2 different AIs and they both said the password was parola. It was not. Look at it:

```bash
┌──(lenad㉿lenadkali)-[~/WorkSpace/Machines/Snapped]
└─$ hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt 
hashcat (v7.1.2) starting
INFO: All hashes found as potfile and/or empty entries! Use --show to display them.

┌──(lenad㉿lenadkali)-[~/WorkSpace/Machines/Snapped]
└─$ hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt --show
$2a$10$8M7JZSRLKdtJpx9YRUNTmODN.pKoBsoGCBi5Z8/WVGO2od9oCSyWq:linkinpark
```

- Well. Whatever. This was not my bad, nor something "I had not known". `jonathan:linkinpark` gives access to the machine as user *jonathan* via SSH.
- Got user flag, starting PrivEsc.

---
## PrivEsc

-  HAHAHAHHAHA. Ok I had to do it once in my life. I used [[DirtyFrag]], a kernel level PrivEsc path that chains two CVEs to give instant root. I will now and explain the intended path:

Oh. Okay. Ummmmmmmmmm...
I don't even begin to understand the PrivEsc path. Ok tbf this was very out of my range of knowledge. Nice to have used [[DirtyFrag]] tho HAHHA.

---
## Rabbit holes

 - Trying to forge a JWT token (found the secret on app.ini from the CVE), or use node secret to become admin in the NginxUI.

---
## Attack chain

- Run basic scan and find vhost admin.snapped.htb
- Find NGinxUI version and find [[CVE-2026-27944]].
- Use the PoC, get a dump of the backup, and find the DB where the creds are stored.
- Crack Jonathan's hash and SSH in as jonathan.
- Get user flag.
- Use [[DirtyFrag]] to get root.
- Get root flag.

---
## Learnt

- I'm still not able to do hard level machines lol.

---
## Notes  
- Machine rating: hard.
  
  