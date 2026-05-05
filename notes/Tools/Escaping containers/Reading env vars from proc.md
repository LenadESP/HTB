## Reading environment variables from a process

### Command

```bash
cat /proc/1/environ | tr '\0' '\n' 
```

### What it does

Displays all environment variables of process ID 1 (the main process), formatted line by line.

### Why it works

- `/proc/<PID>/environ` is a kernel‑provided file containing the environment variables passed to a process at startup.
- PID `1` is the first process (init or container entrypoint); its environment often contains secrets (API keys, DB passwords, tokens).
- Environment variables are stored **null‑separated** (`\0`), not newline‑separated, so `cat` alone shows garbled output.
- `tr '\0' '\n'` replaces null bytes with newlines, making each `KEY=value` appear on its own line.
### Use case

Inside a compromised container or after breaking into a system, reading `PID 1`'s environment often reveals credentials to pivot to other services (host, database, cloud APIs).