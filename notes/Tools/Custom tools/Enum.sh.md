
Automates the initial enumeration phase for HTB machines. Runs nmap and vhost fuzzing in the background while recursively fuzzing endpoints layer by layer in the foreground. Prints a live ASCII tree as it discovers paths, and saves the full tree to `tree.txt` when done.

## My usage

```bash
./enum.sh \
  -w1 /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-words.txt \
  -w2 /usr/share/wordlists/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt \
  -wv /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-words.txt \
  -wf /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-files.txt
```

## Usage

```bash
./enum.sh [-n NAME] [-i IP] [-d DOMAIN] [-w1 WORDLIST1] [-w2 WORDLIST2] [-wv VHOST_WORDLIST] [-ext EXTENSIONS]
```

All flags are optional. Whatever you don't pass, it'll ask for.

## Flags

| Flag   | Description                                                                      | Required? |
| ------ | -------------------------------------------------------------------------------- | --------- |
| `-n`   | Machine name                                                                     | Yes       |
| `-i`   | Target IP                                                                        | Yes       |
| `-d`   | Domain (e.g. `machine.htb`)                                                      | Yes       |
| `-w1`  | Absolute path to endpoint wordlist 1                                             | Yes       |
| `-w2`  | Absolute path to endpoint wordlist 2                                             | No        |
| `-wv`  | Absolute path to vhost wordlist                                                  | No        |
| `-wf`  | Absolute path to file fuzzing wordlist (default: falls back to `-w1`)            | No        |
| `-ext` | Comma-separated file extensions to fuzz<br>(default: `php,html,js,txt,json,xml`) | No        |

## Output files

| File | Contents |
|---|---|
| `nmap.txt` | Full nmap scan (`-sS -sC -sV -p-`) |
| `tree.txt` | ASCII tree of all discovered endpoints and files |
| `vfuzz.txt` | ffuf vhost results (JSON) |

Files are saved in the directory where the script is run from.

## How recursive fuzzing works

The script uses BFS (breadth-first) to fuzz endpoints layer by layer:

1. Fuzzes `/FUZZ` with both wordlists + file extensions
2. Any directories found (e.g. `/api`) are queued for the next layer
3. Next layer fuzzes `/api/FUZZ`, finds `/api/auth`, queues that
4. Repeats until no new directories are found

Files (anything with an extension) are fuzzed at every layer but never recursed into. The tree is printed to terminal after every path finishes, so you can see results in real time without waiting for the whole scan.

```
machine.htb
    └── /api
        └── /auth
            └── /login
        └── /users
    └── /assets
        └── /index.js
```

## Examples

```bash
# Full interactive mode
./enum.sh

# Pass everything, no prompts
./enum.sh -n Editor -i 10.10.11.232 -d editor.htb \
  -w1 /path/to/raft-large-words.txt \
  -w2 /path/to/directory-list-2.3-medium.txt \
  -wv /path/to/raft-large-words.txt \
  -wf /path/to/raft-large-files.txt

# Custom extensions
./enum.sh -n Editor -i 10.10.11.232 -d editor.htb -w1 /path/to/wordlist.txt -ext php,asp,aspx
```

## Notes

- Don't add `http://` to the domain, the script handles that.
- nmap and vhost fuzzing run in the background while endpoint fuzzing runs in the foreground.
- Recursive fuzzing can take a long time on machines with deep endpoint trees. That's expected.
- If `-wf` is not provided, file fuzzing falls back to `-w1`. It works but `raft-large-files.txt` is much better for finding actual files.
