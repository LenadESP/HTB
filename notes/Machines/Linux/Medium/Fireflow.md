# HTB - Fireflow

---
## General Info
- OS: Linuz
- Open ports: 22, 443
- Running services: Langflow:flow:80(1.8.2)
- Endpoints: -
- VHosts: flow.fireflow.htb
- Auth: -
- Pwnd date:

---
## Enumeration  

- Ran nmap, vhost fuzz, etc.
- Found Langflow on vhost flow.fireflow.htb, running version 1.8.2, which is vulnerable to RCE [[CVE-2026-33017]], I'll try a PoC.
- Okay so... I'm seeing a contradiction. Although many articles claim that version 1.8.2 is vulnerable to an unauthenticated RCE attack, the PoC used in the article is asking me for a  JWT token. I'll look further into this issue. Also, I'll fuzz the main page, which I have almost forgotten at this point, jic. Okay. Nothing. I'mma dive in how the PoC works, and why it isn't working.
- Okay yeah that was dumb. It asks for either a JWT token OR a flow id, which we can get from the main page. Now I'm getting an SSL error. I'mma parse the code so that this doesn't happen.
- Well. I'm now getting 403d. Fucking hell.
  
---
## Exploitation  

- HEHEHEH. Ok. Two tricks. One, added debugging to the PoC and guess, only the verification was wrong. Curling my server pinged it.
- Two. Sending the reverse shell over JSON is... complicated. So I hosted a script with the bash shell and just curled it and piped it into bash. Works. I got a foothold as *www-data*. Starting lateral privesc

---
## Lateral PrivEsc

-**Current foothold**

- Interesting:
    - localhost:8080 (Uvicorn)
    - Kubernetes components
    - Langflow installation
    - Any credentials/configs
- Ignore:
    - Everything I started chasing out of sleep deprivation. 
  
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
  
  