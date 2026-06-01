## What is it

Probing a hash against a list of candidate passwords (a wordlist) to try and guess the password that produced it. The attack happens entirely offline — once you have the hash, the target isn't involved anymore, so no rate limits, no lockouts, no logs.

The two main tools are:

- **John the Ripper** (`john`) — CPU-friendly, smart defaults, auto-detects most hash formats. Best for "I just want to throw rockyou at this and see what sticks."
- **Hashcat** (`hashcat`) — GPU-accelerated, faster but requires you to specify the exact hash mode (`-m`). Best for big jobs or when you know what you're cracking.

For both, you need:

1. The hash (in the right format — sometimes you need a helper script to extract it)
2. A wordlist (`/usr/share/wordlists/rockyou.txt` is the default classic)
3. The mode/format identifier so the tool knows what it's cracking

---

## Common modes

> Hashcat `-m` modes I keep running into. John usually auto-detects, but if it doesn't, use `--format=`.

| What                   | Hashcat `-m` | John `--format` | Notes                                  |
| ---------------------- | ------------ | --------------- | -------------------------------------- |
| MD5                    | 0            | raw-md5         | Trivially fast                         |
| SHA-1                  | 100          | raw-sha1        | Trivially fast                         |
| SHA-256                | 1400         | raw-sha256      | Fast                                   |
| bcrypt                 | 3200         | bcrypt          | Slow on purpose — wordlist only        |
| NTLM                   | 1000         | NT              | Windows hashes from `secretsdump` etc. |
| NetNTLMv2              | 5600         | netntlmv2       | From `responder` captures              |
| Kerberos AS-REP        | 18200        | krb5asrep       | AS-REP roasting                        |
| Kerberos TGS-REP       | 13100        | krb5tgs         | Kerberoasting                          |
| JWT HS256              | 16500        | —               | Weak JWT secrets                       |
| PDF 1.4-1.6 (R3/R4)    | 10500        | pdf             | RC4 / older PDFs                       |
| PDF 1.7+ (R6, AES-256) | 10700        | pdf             | Slow as hell, wordlist only            |
| ZIP (PKZIP)            | 17200        | zip             | Use `zip2john`                         |
| 7-Zip                  | 11600        | 7z              | Use `7z2john`                          |
| Linux shadow (SHA-512) | 1800         | sha512crypt     | From `/etc/shadow`                     |

---

## Tooling

**The `2john` family** — helper scripts that extract crackable hashes from various file formats. They live in `/usr/share/john/` (Kali default). Output looks like `filename:$format$params...` and is what you feed to john or hashcat.

|Script|Use for|
|---|---|
|`pdf2john.pl` / `pdf2john.py`|PDFs|
|`zip2john`|ZIP archives|
|`7z2john.pl`|7z archives|
|`rar2john`|RAR archives|
|`ssh2john.py`|Encrypted SSH private keys|
|`keepass2john`|KeePass `.kdbx` databases|
|`office2john.py`|Office docs (.docx, .xlsx with password)|
|`gpg2john`|GPG private keys|

**Typical pattern:**

```bash
<format>2john target.file > hash.txt
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
john --show hash.txt
```

For hashcat, strip the filename prefix first (john keeps `filename:` at the start of each line, hashcat doesn't want it):

```bash
<format>2john target.file > hash.txt
sed 's/^[^:]*://' hash.txt > hash.clean
hashcat -m <mode> hash.clean /usr/share/wordlists/rockyou.txt
```

---

## Payloads

**Generic — bcrypt with rockyou:**

```bash
hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt
```

**Generic — john auto-detect:**

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
john --show hash.txt          # display cracked passwords
```

**Resume a john session that you ctrl+C'd:**

```bash
john --restore
```

**Rule-based attack** (mutates words from the wordlist — `Password` → `Password1`, `P@ssw0rd`, etc.):

```bash
hashcat -m <mode> hash.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```

---

## PDF

> PDFs use one of two encryption families depending on PDF version. Know which one before you queue a long crack.

**Identifying the encryption:** look at the encryption dictionary inside the PDF. `/R 3` or `/R 4` = older (RC4), `/R 5` or `/R 6` = newer (AES-256). `/V` indicates the algorithm version. Easiest way:

```bash
pdfinfo target.pdf | grep -i encrypt
# or just look at the pdf2john output — the hash format encodes R and V
```

**Extract the hash:**

```bash
# location varies by distro — locate it first
locate pdf2john
# Kali default:
python3 /usr/share/john/pdf2john.py target.pdf > pdf.hash
# (or pdf2john.pl on some distros — both exist, both work)
```

**Crack with john (handles either R3/R4 or R6 transparently):**

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt pdf.hash
john --show pdf.hash
```

**Crack with hashcat (need to pick the right mode):**

```bash
# Strip filename prefix first
sed 's/^[^:]*://' pdf.hash > pdf.hash.clean

# Older PDFs (RC4, R3/R4)
hashcat -m 10500 pdf.hash.clean /usr/share/wordlists/rockyou.txt

# Modern PDFs (R6, AES-256) — slow, wordlist only
hashcat -m 10700 pdf.hash.clean /usr/share/wordlists/rockyou.txt
```

**Reality check on R6/AES-256 speed:** mode 10700 is designed to be expensive (many iterations). Even with a GPU you're looking at low hundreds of H/s; on CPU you'll be lucky to hit double digits. Pure brute force is not viable — **wordlist attacks only**. If rockyou doesn't pop it, build a themed wordlist from box context (usernames, service names, hostnames, things you've seen in configs) rather than burning hours.

**Real example ([[Helix]]):**

- Encrypted operator manual sitting in `/home/operator/` next to the user flag
- `pdf2john.py target.pdf > pdf.hash` → cracked by john + rockyou in ~5 min
- PDF contained the full spec for the OPC UA reactor system — knowing the trip thresholds and maintenance window conditions was the entire privesc path