### What is it

`dirsearch` is a Python-based web path brute-forcer. More thorough than ffuf for general web enumeration — it handles extensions, recursion, and filtering out of the box without much setup.

---

### What it does

- Brute-forces endpoints and directories on web servers
- Appends extensions to wordlist entries automatically
- Recursively brute-forces found directories
- Filters responses by status code, size, or text
- Saves and resumes scan sessions

---

### Common Options

|Option|What it does|
|---|---|
|`-u`|Target URL|
|`-w`|Wordlist path|
|`-e`|Extensions to append (e.g. `php,html,js`)|
|`-f`|Force-append extensions to every entry (use with SecLists)|
|`-r`|Recursive scan|
|`-R`|Max recursion depth|
|`-t`|Threads (default: 25)|
|`-i`|Only show these status codes (e.g. `200,301`)|
|`-x`|Exclude these status codes (e.g. `403,404`)|
|`--exclude-sizes`|Exclude responses by size (e.g. `0B,4KB`)|
|`-o`|Output file|
|`--format`|Output format (`plain`, `json`, `html`, `md`...)|
|`--proxy`|Proxy (e.g. `127.0.0.1:8080` for Burp)|
|`--random-agent`|Randomize User-Agent per request|

---

### Typical Usage

**Basic scan:**

```bash
python3 dirsearch.py -u http://target.htb
```

**With extensions:**

```bash
python3 dirsearch.py -u http://target.htb -e php,html,js
```

**With custom wordlist + extensions:**

```bash
python3 dirsearch.py -u http://target.htb -w /path/to/wordlist.txt -e php,html
```

**With SecLists wordlist (needs -f):**

```bash
python3 dirsearch.py -u http://target.htb -w /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt -f -e php,html,js
```

**Recursive:**

```bash
python3 dirsearch.py -u http://target.htb -e php,html -r -R 3
```

**Only show 200s:**

```bash
python3 dirsearch.py -u http://target.htb -e php -i 200
```

**Save output:**

```bash
python3 dirsearch.py -u http://target.htb -e php -o results.txt --format plain
```

---
### Notes
- If using SecLists wordlists, always add `-f` — otherwise extensions won't get appended.
- Default extensions in `config.ini` are `php,aspx,jsp,html,js` — you can change them there permanently.
- CTRL+C during a scan lets you pause and save the session to resume later.