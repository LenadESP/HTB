Automates the initial enumeration phase for HTB machines. Runs nmap and ffuf (endpoints + vhosts) in parallel, prompting only for whatever info wasn't passed as a flag.

## My usage

```bash
./enum.sh -w1 /usr/share/wordlists/dirb/big.txt -w2 /usr/share/wordlists/dirbuster/directory-list-1.0.txt -wv /usr/share/wordlists/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt
```
## Usage

```bash
./enum.sh [-n NAME] [-i IP] [-d DOMAIN] [-w1 WORDLIST1] [-w2 WORDLIST2] [-wv VHOST_WORDLIST]
```

All flags are optional. Whatever you don't pass, it'll ask for.
## Flags

|Flag|Description|Required?|
|---|---|---|
|`-n`|Machine name|Yes|
|`-i`|Target IP|Yes|
|`-d`|Domain (e.g. `machine.htb`)|Yes|
|`-w1`|Absolute path to endpoint wordlist 1|Yes|
|`-w2`|Absolute path to endpoint wordlist 2|No|
|`-wv`|Absolute path to vhost wordlist|No|

## Output files

|File|Contents|
|---|---|
|`nmap.txt`|Full nmap scan (`-sS -sC -sV -p-`)|
|`fuzz.txt`|ffuf endpoint results (if only `-w1` provided)|
|`fuzz1.txt` / `fuzz2.txt`|ffuf endpoint results (if both `-w1` and `-w2` provided)|
|`vfuzz.txt`|ffuf vhost results|

Files are saved in the directory where the script is run from.

## Examples

```bash
# Full interactive mode
./enum.sh

# Pass everything, no prompts
./enum.sh -n Editor -i 10.10.11.232 -d editor.htb -w1 /path/to/common.txt -wv /path/to/subdomains.txt

# Pass some flags, prompt for the rest
./enum.sh -i 10.10.11.232 -d editor.htb
```

## Notes

- Don't add `http://` to the domain, the script handles that.
- If a job dies in under 3 seconds, the script prints its output to console so you can see what went wrong.
- nmap starts running while you're still answering the wordlist prompts.