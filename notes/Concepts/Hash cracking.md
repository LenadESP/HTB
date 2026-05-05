## What is it  
Probing a hash against to a list of words to try and guess the password.

## Payloads  
```bash
hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt
```