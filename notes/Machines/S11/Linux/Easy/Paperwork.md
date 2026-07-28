# HTB - Paperwork

---
## General Info
- OS: Linux
- Open ports: 22, 80, 1515
- Running services: OpenSSH:(10.0p2), nginx:80(1.28.0)
- Endpoints: I don't give a FUCK about them
- VHosts: -
- Auth: well lol
- Pwnd date:

---
## Enumeration  

- Ran basic shit (you already know these)
- Found the main page under paperwork.htb, and it gave me the source code for a custom server that is running on port 1515, I read it, and GUESS. I love this. Remember the command escape we used in a previous machine (' #)? Well this is also vulnerable, in this line of code:
 
```python
subprocess.Popen(f"echo 'Archive: {job_name}' >> /tmp/archive.log", shell=True)
```

- I'mma try to communicate with the server and I'll report back.
  
---
## Exploitation  

-  HEHEHHEE

```bash

```

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
  
  