## What it is
**nmap** (Network Mapper) is a network discovery and security scanning tool. It finds hosts, open ports, running services, and OS fingerprints.

---

## What it does
- Host discovery (ping sweeps)
- Port scanning (TCP/UDP)
- Service/version detection
- OS fingerprinting
- Script scanning (vulnerability detection, enumeration)

---
## Repo

https://github.com/nmap/nmap

---

## Usage

Basic syntax:

```bash
nmap [options] <target>
```
### Example: Service + script scan on common ports

```bash
nmap -sC -sV -p 22,80,443 127.0.0.1
```

### My command
```bash
nmap -sC -sS -sV -p- 127.0.0.1
```

---
## Notes

- `-sC` runs default safe scripts.
- `-sV` detects service versions.
- `-p-` scans all 65535 ports (slow).
- `-O` attempts OS fingerprinting.
- Use `-T4` for faster timing (avoid `-T5` unless you want to be aggressive).