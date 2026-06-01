# HTB - Blue

---
## General Info
- OS: Windows 7 Pro
- Open ports: 135, 139, 445
- Running services: SMB
- Endpoints: -
- VHosts: -
- Auth: lol idk
- Pwnd date: 1/6/2026

---
## Enumeration  

- Ran nmap and nmap script `smb-enum-shares` to enumerate [[SMB]] shares.
- Found the machine running Windows 7 SP1, which is a candidate for [[MS17-010 (EternalBlue)]] (WannaCry, NotPetya... sounds familiar?) (I don't even know how the writeup came to this conclusion just based on the version but wtv).
- Will try a public PoC I found.
  
---
## Exploitation  

-  Well actually I ended up using MS' module, which is even cooler because it automatically translates my Linux commands to Windows', so I can use commands such as ls, cd, cat etc. 
- I got a root shell straight up so I grabbed the user and root flag.

---
## Rabbit holes
 -  LOL

---
## Attack chain
- Ummm...
- Find SP1 running and identify a possibly vulnerable machine to [[MS17-010 (EternalBlue)]]
- Execute [[Metasploit]] module `exploit/windows/smb/ms17_010_eternalblue` to check whether it's vulnerable.
- Grab user and root flag.
---
## Learnt

- How to enumerate SMB. lol that's actually it.
  
---
## Notes  
- Machine rating: Easy.
- I used guided mode and the walkthrough as hell.
  
  