## What it is

**FFuF** = fast web fuzzer. Finds hidden directories, files, parameters, vhosts. It replaces `FUZZ` with words from a wordlist and checks responses. 

---

## What it does

- Directory & file discovery
- Vhost enumeration (even without DNS)
- Parameter fuzzing (GET/POST/headers)
- Recursive scanning
- Filtering by status, size, words, lines, regex

---

## Repo
https://github.com/ffuf/ffuf

---

## Usage

### Typical me wordlist
```/wordlists/Discovery/Web-Content/raft-large-directories.txt ```

Basic syntax:

```bash
ffuf -w <wordlist> -u <URL> [options]
```

### Example 1: Directory discovery

```bash
ffuf -w /usr/share/wordlists/dirb/common.txt 
-u https://target.com/FUZZ 
-fc 404
```

### Example 2: Vhost discovery

```bash
ffuf -w subdomains.txt 
-u https://target.com 
-H "Host: FUZZ.target.com"
-fs 4242
```

---

## Notes

- `FUZZ` is the placeholder. Change it with `-w wordlist.txt:KEY`.
- Filter out false positives using `-fc`, `-fs`, `-fr`.
- Use `-ac` for auto‑calibration (filters common garbage).