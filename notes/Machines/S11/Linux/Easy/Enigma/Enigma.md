# S11 - Enigma

---
## General Info
- OS: Linux Ubuntu kernel 6.8.0-124-generic
- Open ports: 22, 80, 110, 111
- Running services: Nginx:80, Dovecot, NFS server, Roundcube:mailto001(1.6.16), OpenSTAManager:support_001(2.9.8)
- Endpoints: -
- VHosts: mail001.enigma.htb, support_001(2.9.8)
	- /plugins
- Auth: -
- Pwnd date: 01/07/2026

---
## Enumeration  

- Ran basic enumeration (nmap, fuzzing, etc), and I got a whole list of fucking ports. Lemme tell ya, I know about 3 lol.
- Okay. So. We have some cool things. On the one side, we have a mail service running, on the other, a [[NFS (network file system)]] server.
- After mounting the exposed folder, I got a pdf with some default creds, `kevin:Enigma2024!`, for new staff. Lemme say, they did in fact not change it as it says in the pdf. I have access to the Roundcube main panel. 
- I searched for known CVEs, but this panel is up to date, and there's only an email, with no interesting information.
- Okay. I slept (it was 4 am), and there's things I overlooked. First, I tried reusing the credentials on SSH. Interestingly enough, we get asked for a key, so either it is leaked or we need a reverse shell. Then, I fuzzed the main page (I instantly went for the mail001 vhost), but nothing came back, so now I'm 90% sure the main page is just a decoy. And third, the email received by kevin was sent by sarah. Well. Guess what. Sarah also has the default password. And yeah. Well. Read.
  
> Hi Sarah,  
  >
> Apologies for the delay. I have provisioned your access. Please find the details below:  
  >
  >URL: [http://support_001.enigma.htb](http://support_001.enigma.htb/)  
  >Username: admin  
  >Password: Ne3s4rtars78s  
  >
> Note: I will create a dedicated account for you shortly, for now you can use the admin account to get started.  
>
> Regards,  
> IT Support  
> Enigma Corp

- Okay. Fair enough. Lemme see what this is all about. Okay. So. After getting in with the admin credentials, I was able to find a [[CVE-2025-69215]], a [[SQLi]] injection CVE that dumped me the whole database. There's two users, one, admin, which we already know the credentials for, and `haris:bestfriends`, which I got after breaking the hash. I will try both in the mail service discovered before. Ok, haris works but has no email, admin doesn't. 
  
---
## Exploitation  

-  God. Dang it. Okay. Getting a foothold was MESSY. So. Here's the thing. In that support page, you can upload modules, and in that service, OSTAM, as admin, you can upload modules. These modules, are like plugins, and they need both a MODULE file, .ini formatted, with basic information about the plugin, and php files. You see where I'm going? I uploaded a reverse shell. And it worked. After fighting leftover tmp files lol (I had to reset the machine). So, I got a shell as user `www-data`. Starting lateral PrivEsc. (*Read the Rabbit Holes section, I tried to exloit the backups.*)
  
---
## Lateral PrivEsc

- Ok, this is gonna be important now that I've listed the users in the machine, so here's a list of all credentials I have so far.
  
> `kevin:Enigma2024!`
> `sarah:Enigma2024!`
> `haris:bestfriends`
> `admin:Ne3s4rtars78s`

- Bingo. Basically, there's 4 users in /home, sarah, kevin, it and haris. What I did was read /etc/passwd, grepping for *nologin*, (thanks claude), and I found that I could only log in as haris. Well. I got user flag (with the password cracked before). Starting PrivEsc.
  
> Side note, this is why grepping works
> kevin:x:1001:1001::/home/kevin:/usr/sbin/nologin
   sarah:x:1002:1002::/home/sarah:/usr/sbin/nologin
   it:x:1003:1003::/home/it:/usr/sbin/nologin

---
## ## PrivEsc

-  Okay, while listing the machine following [[Privilege Escalation - Common Library | PrivEsc Library]], I found an interesting service, OliveTin, listening on localhost, port 1337. I sent it back to my machine using [[Chisel - Exposing internal ports | Chisel]]. 
- Okay, this is a webpanel that executes predefined commands.
- Oooookay. Damn. This was HARD. Basically, reading the docs + the config, I found [[CVE-2026-27626]]. TL;DR: OliveTin's shell-mode safety check blocks a bunch of dangerous argument *types*, but it forgot one — `password`. So any arg typed as `password` skips the check and its value goes straight into `sh -c`. Command injection, baby.

- Now, the config. First one I read was the stock example config, which sent me on a goose chase (no `password` args, no webhooks, nothing). Took me THREE tries to confirm I was reading the config the service was actually loading. Lesson: confirm your damn config is live before you build against it.

- The live config had a juicy action hiding in the boilerplate:

> shell: "mysqldump -u {{ db_user }} -p'{{ db_pass }}' {{ db_name }} > /opt/backups/backup.sql"
> db_pass -> type: password

- There she is. `db_pass` is `type: password`, and it sits **inside single quotes** (`-p'...'`). So my payload isn't just `; id` — I have to break OUT of that single-quote context first, run my thing, then comment out the tail so the rest of the line doesn't throw a syntax error. Shape: `'; <command> #`.

- Auth: `authRequireGuestsToLogin: false` + `defaultPermissions.exec: true`, so I can hit the API as an unauthenticated guest. Confirmed it — I could call actions with zero creds.

- BUT. My curls kept 404ing (`action not found`). Turns out the real endpoint isn't `/api/StartAction` — I had to sniff the web UI's own request and copy it: `/api/olivetin.api.v1.OliveTinApiService/StartAction`, and the key is `bindingId`, NOT `actionId`. Once I matched the UI's exact request shape, it fired.

- Also confirmed the CVE thesis live: sending `; id;` to the `host` arg (typed `ascii_identifier`) got rejected — `doesn't match ascii_identifier`. Same exact string sails through `db_pass`. The type check WORKS, it just doesn't cover `password`. Beautiful.

- First payload was a reverse shell... which died the SECOND it connected. OliveTin's action has a timeout, my shell was a child of that action's process, action gets reaped -> my shell gets reaped with it. Connect, die, same second.

- Instead of fighting the process lifecycle, I sidestepped it. Classic move: drop a SUID bit instead of holding a live shell. Payload: `'; chmod +s /bin/bash #`. No sockets, no timeout, nothing to reap — it just flips the bit as root and exits.

> curl 'http://127.0.0.1:1337/api/olivetin.api.v1.OliveTinApiService/StartAction' \
>   -H 'content-type: application/json' -H 'connect-protocol-version: 1' \
>   --data-raw '{"bindingId":"backup_database","arguments":[{"name":"db_user","value":"backup_svc"},{"name":"db_pass","value":"'\''; chmod +s /bin/bash #"},{"name":"db_name","value":"production"}],"uniqueTrackingId":"..."}'

- Then on my existing shell: `/bin/bash -p` (the `-p` is the part people forget — keeps euid=0 instead of dropping privs), `id` -> euid=0(root), `cat /root/root.txt`. Rooted.

---
## Rabbit holes

 - Tried to exploit OSTAM backup system to upload a reverse shell, but it was VERY petty, so wellp.
 - networkd-dispatcher CVE-2022-29799, running as root but requires race, wrong difficulty tier.

---
## Attack chain

- Mount unauthenticated NFS export, recover onboarding PDF with default creds `kevin:Enigma2024!`.
- Log into Roundcube webmail. Reuse creds on `sarah`, read email leaking `admin:Ne3s4rtars78s` for OpenSTAManager. 
- Log into OpenSTAManager as admin. 
- Exploit [[CVE-2025-69215]] (SQLi) to dump the DB. 
- Crack recovered hash -> `haris:bestfriends`. 
- Upload a PHP reverse shell via OSTAM module upload (MODULE .ini + php) to get foothold as `www-data`. 
- Grep `/etc/passwd` for valid shells -> only `haris` can log in. 
- Log in as `haris` (reused creds).
- Get user flag. 
- Enumerate local services, find OliveTin on `127.0.0.1:1337`, forward it home with [[Chisel - Exposing internal ports | Chisel]]. 
- Exploit [[CVE-2026-27626]] (`password`-type arg injection) via the unauth guest API into the `backup_database` action -> `chmod +s /bin/bash` as root. 
- Run `/bin/bash -p` to keep euid=0. 
- Get root flag.

---
## Learnt

- I don't even know. this machine is LONG as fuck.
  
---
## Notes  
- Machine rating: Meh. Easy ish, to medium. Required some actual thinking
