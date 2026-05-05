# Privilege Escalation - Common Library

This is a PrivEsc common library, that gathers all generic techniques (and not so generic) I've gathered and that I will gather throughout my journey on HTB. It'll be divided in different sections:

- [[Privilege Escalation - Common Library#Generic|Generic]]: Commands you should run in all machines
    - [[Privilege Escalation - Common Library#Who am I? What permissions do I have?|Who am I? What permissions do I have?]]
    - [[Privilege Escalation - Common Library#What is (in) the system? Who else is in the system?|What is (in) the system? Who else is in the system?]]
    - [[Privilege Escalation - Common Library#What is listening? What is running?|What is listening? What is running?]]
    - [[Privilege Escalation - Common Library#Extended permission checking|Extended permission checking]]
    - [[Privilege Escalation - Common Library#Sensitive files & credentials|Sensitive files & credentials]]
    - [[Privilege Escalation - Common Library#Capabilities|Capabilities]]

---
## Generic

> Run these on every machine, no matter what. They paint the full picture before you go deep.

---

### Who am I? What permissions do I have?

|Command|Description|
|---|---|
|`whoami`|Prints your current username|
|`id`|Shows user ID (uid), group ID (gid), and all the groups you're in|
|`sudo -l`|What can I run as sudo?|
|`env`|Shows environment variables — look for credentials, paths, tokens|

**Writable files hunt:**

```bash
find / -writable -type f 2>/dev/null | grep -v proc | grep -v sys
```

Finds regular files writable by the current user, excluding `/proc` and `/sys` (virtual filesystems).

- `-writable` = match writable files, `-type f` = regular files only (not directories), `2>/dev/null` = discard errors, `grep -v` = exclude lines containing that pattern

---

### What is (in) the system? Who else is in the system?

| Command               | Description                                                                              |
| --------------------- | ---------------------------------------------------------------------------------------- |
| `uname -a`            | Prints system information: kernel version, architecture (x86/x64/ARM)                    |
| `cat /etc/os-release` | Distribution name and version (Ubuntu, Debian, etc.)                                     |
| `ls -la /home/`       | Lists all folders (and thus users) in /home. `-l` = long listing (perms etc), `-a` = all |

**Users with a shell:**

```bash
cat /etc/passwd | grep -E "/bin/bash|/bin/sh"
```

Shows which users have a `/bin/bash` or `/bin/sh`.

- In `grep -E`, `-E` = extended regex, which allows alternation `(|)`. So it greps for `/bin/bash` or `/bin/sh`

**Recently modified files (last 10 min):**

```bash
find / -type f -mmin -10 2>/dev/null | grep -v proc | grep -v sys
```

Useful for spotting freshly written scripts, configs, or credentials — e.g. a cronjob just ran and wrote something.

- `-type f` = regular files only, `-mmin -10` = modified less than 10 minutes ago, `2>/dev/null` = hide errors, `| grep -v proc | grep -v sys` = pipe the results and exclude `/proc` and `/sys` (virtual filesystems that would flood the output with noise)

---

### What is listening? What is running?

**Running processes:**

```bash
ps aux
ps aux | grep root      # filter for root-owned processes only
```

- `a` = show processes from all users, `u` = show the user who owns each process, `x` = include processes not attached to a terminal (background stuff)

**Scheduled tasks:**

```bash
cat /etc/crontab                          # system-wide crontab
ls -la /etc/cron*                         # all cron directories (daily, weekly...)
cat /var/spool/cron/crontabs/* 2>/dev/null# per-user crontabs
```

**Open ports & listeners:**

```bash
netstat -tulpn 2>/dev/null
ss -tulpn 2>/dev/null        # modern alternative to netstat, same flags
```

Shows listening TCP/UDP ports, program name, and PID. Useful to spot internal services that aren't exposed externally.

- `-t` = TCP, `-u` = UDP, `-l` = listening only, `-p` = show process name/PID, `-n` = numeric (skip DNS resolution, faster)

---

### Extended permission checking

**SUID binaries** (run with the _owner's_ privileges — often root):

```bash
find / -perm -4000 -type f 2>/dev/null
```

- `-perm -4000` = SUID bit set, `-type f` = regular files, `2>/dev/null` = hide errors
- Cross-reference findings on [GTFOBins](https://gtfobins.github.io/)

**SGID binaries** (run with the _group's_ privileges):

```bash
find / -perm -2000 -type f 2>/dev/null
```

- `-perm -2000` = SGID bit set, `-type f` = regular files, `2>/dev/null` = hide errors

**World-writable directories** (potential hijack spots):

```bash
find / -type d -perm -0002 2>/dev/null | grep -v proc
```

- `-type d` = directories only, `-perm -0002` = writable by anyone (the last `2` in the octal = "others can write")

**Files owned by root but writable by others:**

```bash
find / -user root -writable -type f 2>/dev/null | grep -v proc | grep -v sys
```

- `-user root` = owned by root, `-writable` = but still writable by you. That's a misconfiguration you can abuse.

---
### Sensitive files & credentials

> Always check these — hardcoded creds and keys are embarrassingly common.

---

**System files:**
- `cat /etc/shadow` -> Hashed passwords. Needs root or shadow group to read, but worth trying.

---

**Shell history** (people type passwords in plaintext more than you'd think):

```bash
cat ~/.bash_history
cat ~/.zsh_history
cat /root/.bash_history 2>/dev/null
```

---

**Config files that often leak creds:**

```bash
find / -name "*.env" 2>/dev/null          # hardcoded DB passwords, API keys, etc.
find / -name "wp-config.php" 2>/dev/null  # WordPress config, almost always has DB creds in plaintext
find / -name "config.php" 2>/dev/null
```

- `-name` = match by filename, supports wildcards like `*.env` (any file ending in `.env`)

---

**SSH keys:**

```bash
find / -name "id_rsa" 2>/dev/null         # private RSA key — jackpot if found
find / -name "id_ed25519" 2>/dev/null     # same but Ed25519 (newer key type)
cat ~/.ssh/authorized_keys                # shows who can log in as this user via SSH
```

---
### Capabilities

> Capabilities are like a more granular SUID — instead of giving a binary full root, they give it just one specific privilege. Often overlooked, often misconfigured.

---

```bash
getcap -r / 2>/dev/null
```

Lists all binaries with special Linux capabilities set.

- `-r` = recursive (search from `/`), `2>/dev/null` = hide errors

**Things to look for in the output:**

- `cap_setuid` -> can change its own UID -> effectively root
- `cap_dac_override` -> bypass file read/write permissions
- `cap_net_raw` -> raw sockets (can sniff traffic)

Cross-reference findings on [GTFOBins](https://gtfobins.github.io/) under the _Capabilities_ filter.