# HTB - Helix

---
## General Info
- OS: Linux
- Open ports: 22, 80
- Running services: OpenSSH:22(8.9p1), Nginx:80(1.18.0), NiFi:80(1.21.0)
- Endpoints:
- VHosts: flow.helix.htb
- Auth:
- Pwnd date:

---
## Enumeration  

- After running basic enumeration (nmap, fuzzing and vhost fuzzing), I went to the main page in port 80 and found basically nothing. But I had found a vhost, and after adding it to `/etc/hosts`, I found a webpanel running NiFi (V1.21.0), which had a known [[CVE-2023-34468]], which can lead to RCE, and ultimately, to a Reverse Shell. Trying that.

---
## Exploitation  

-  Yup. After trying the [[CVE-2023-34468#PoC|PoC]], I got a reverse shell as user *nifi*. I upgraded the reverse shell ([[Reverse Shell#Upgrade shell|RSUS]]).
- Ok so, the home user is *operator*, which means I have to pivot to that user.

---

I don't even know what to say. I just spent 3H down a cryptographic rabbit hole, thinking that decrypting the keys of NiFi were the way to get to operator. I thought that I had seen operator:(some hash). Well. I didn't. And this was the most time wasting thing in my life.

After searching a writeup, I found this file:
`/opt/nifi-1.21.0/support-bundles/operator_id_ed25519.bak`. A private key to SSH into the user operator. Fuck all my life decisions.

Got user flag and started PrivEsc.

---
## PrivEsc

-  I-. I don't even know what I'm looking at. I got inside the user folder, got the user flag, and found two files. One of them, a PDF that's encrypted. The other, an image about a network of a nuclear reactor or something like that. I will take a break now.

---
## Rabbit holes

 - Thought that keys I saw inside a .json file were for the user *operator*. I saw it written down. Maybe I just imagined it. Who knows. I should sleep more than 5H.

---
## Attack chain

- 

---
## Learnt

- 
---
## Notes  
- Machine rating:
  
  