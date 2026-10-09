# HTB - Machine

---
## General Info
- OS: Linux
- Open ports: 22, 80
- Running services: OpenSSH:22(8.9p1), Nginx:80(1.18.0), Grafana:Kiosk:80(9.5.2)
- Endpoints:
- VHosts: kiosk.jupiter.htb:
- Auth: well lol
- Pwnd date: 09/10/2026

---
## Enumeration  

- Nmap, vhost fuzz... y'all know the drill already.
- Ok, grafana is running on kiosk. I'll search CVEs.

> Little comment: Claude spoiled that this has something to do with SQL, so yeah. 

- Let's explain what I'm seeing. Basically, the unique (and default) Grafana dashboard is like a blog about moons, that has tables and data and the whole thing. Well. Then let's open burp lol. And no, there's no obvious easy Grafana CVE, in any case, it'd be to chain some CVEs in a weird way I'm not willing to even try XD. 
- LOLOLOLOL. Ok I'm getting into exploitation XD. One sec.

---
## Exploitation  

-  Soooo, basically. All the info on the page is retrieved from a [[PostgresDB#Get shell as sudo|postgress database]]. That request goes in plain text as, yes, literally, a "rawSQL" parameter in the http request to the DB. I have full controll over the query, and I'm a super user on the DB. 
- Okay. This is getting neccessary: I won't explain here how I got RCE, that's a [[PostgresDB#Get shell as sudo |postgres]] specific. I'll write the file after the machine, but for this one, just one thing: I have RCE as *postgress*. I'll write a reverse shell, one sec lol.
- I have a shell as postgress, uid 114, no user flag. There's two other users with a bash in this machine, *juno* and *jovian*. 

---
## Lateral Privesc

-  ... I. Okay. From the beggining, sorry. So, I searched on the "home" of *postgres* (not really a home but ok), found nothing, searched for typicals, didn't find anything, whatever. Searched for writtable files, and found some files and a folder owned by *juno*, with the configuration being -rw-rw-rw, so I can modify it. Basically, the configuration for a service (idc exactly which) that runs every 2 minutes (based on how often the output gets modified). I OBVIOUSLY tried to inject my own script to the config (because it's declared there) and guess. Every idk how much, the system restores that config from the base configuration. So, a race condition.

> A little moment to scream. AHGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHGGGGGGGGGGGHHHHHHHHHHHHHHHGGGGGGGGGGGGGGGHHHHHHHHHHHH
> 
> Ok enough.

- So. I'mma set up a script that just copies my own config on an infinite while. Yeah. Basically force bruting it XD. Let's see if it gets to execute (the script basically copies `/bin/bash`, and `chmod +s` it)

> Mental note: Don't. Listen. To. Opus 4.8.

- Ok, so. I saw that the file was regenerating the file just when the service was being executed, which meant, basically, that the window went from 5s to about microseconds. Yeah nah, that isn't HTB. So, I made Claude check a writeup, and guess? I was right. I had told it several times that "maybe the yml is wrong and the service is regenerating it because of that". Bingo, that was the real explanation. I'mma try to get the yml right and see if I get *juno* or not.
- Ok I'm done with this method. I'll copy what they do in the writeup, add a SSH key basically.
- Finally. I have a shell as juno. SSH. Fucking FINALLY MAN. The issue I've had is that when copying the key, I made a mistake. Okay. Shell as Juno. Let's see what the fuck I get with this shit.
  - # Got. User. Flag

---
## Lateral Privesc2

- I bet both my kidneys that I have to pivot to *jovian*. Let's see what *juno* has given me.
- I'm in the group "science". What the fuck. Ok, let's see which files does sience own.
- Ok, folder `/opt/solar-flares`, owned by *jovian* and *science*, there's a script `start.sh`, with perms -rwxr-xr-x, the rest of the files are -rw-rw----, and the folder is drwxrwx---, so yeah, this is probably my second lateral.
- Ok yeah it was a jupyter notebook instance running, as jovian. It's got a python shell, so I just dropped another key in .ssh, and got ssh as *jovian*. Starting privesc.

---
## PrivEsc

-  Ooookay. So. First, I saw I was in the sudo group, no sudoers, sudo. So I did `sudo -l` to see what I could run as sudo, and saw a no passwd binary, `/usr/local/bin/sattrack`. That binary, when executed, asked for a config, and the strings and stacktrace made me realize that it was searching for it in `/tmp/config.json`.
- I grepped for `config.json` in /, and found a nice little schema in `/usr/local/share/sattrack/config.json`, and guess. Yep. It downloaded a file and placed it wherever I really wanted LOL. 
- Then well pattern-recognition LMFAO, the whole machine has been like this so I generate a ssh key, then I get up a python server, put the remote file name and folder as `/root/.ssh`, and just... sshd in XDDDDDDD. Yeah. LOL.
- Got root flag.

---
## Rabbit holes

 - Thinking the first lateral movement exploit was a race condition LOL

---
## Attack chain

- SQL POST request on JSON to get RCE as *postgres*
- Exploit *juno*'s script to get CE by modifying the config, so you can place an ssh key on it's home.
- Get user flag.
- Get to Jupyter and use python to place another ssh key on *jovian*'s home folder.
- SSH in lol.
- Find nopasswd binary in */usr/local/bin/sattrack*
- Find config schema in */usr/local/share/sattrack/config.json*
- Exploit config to make the binary take my key and place it in */root/.ssh*
- Get root flag.

---
## Learnt

- How to get a shell in a [[PostgresDB#Get shell as sudo |postgress database]].
  
---
## Notes  
- Machine rating: meh, not tooo hard, just a little bit painful and a little bit blind with the scripts and binary.
  
  