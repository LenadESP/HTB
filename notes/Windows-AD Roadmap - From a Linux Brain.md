# Windows / AD Roadmap — From a Linux Brain

> For someone who lives in Linux, hates Windows, and runs everything remotely.
> Core idea: **you attack Windows *from* Kali. You are not moving in. You're raiding.**
> Date: 01/06/26

---

## The mindset fix (read this first)

You don't need to *like* or *live in* Windows. You attack it from your Linux box with Python tools (impacket, netexec, BloodHound, evil-winrm, certipy). You'll spend ~90% of your time in your normal Kali terminal. The Windows shell only shows up *after* you've got a foothold, and even then half the time you're running commands through a Linux tool, not sitting in a GUI.

So the "I can't even `dir`" panic is mostly a non-issue. You'll pick up the 20 commands you actually need in an afternoon.

**You are ~60-70% transferable. Focus your energy on the 30% that's actually new.**

---

## What TRANSFERS (you already own this — leverage it)

| You already know (Linux) | Same thing on Windows |
|---|---|
| Methodology: enum → service+version → foothold → re-enum → privesc | **Identical.** The loop doesn't change. |
| `nmap -sC -sV -p-` | Exact same command, different ports show up |
| ffuf/gobuster, web exploitation (SSRF, XXE, upload, LFI, cmd injection) | Web apps on IIS/ASP.NET/Java — your web skills apply directly |
| "fingerprint version → known CVE → adapt PoC" | Same reflex (e.g. service CVEs, vuln web apps) |
| **Credential reuse / spray everything** | This is *the* core AD skill. Your hard-won habit is now a superpower (password spraying, pass-the-hash). |
| Hash cracking (john/hashcat) | Same tools, same workflow — just different hash *types* (NTLM, NetNTLMv2, Kerberos). Only the hashcat mode number changes. |
| Pivoting (chisel, ssh -L, proxychains) | Same concepts, you'll tunnel through a Windows foothold the same way |
| Privesc *philosophy*: enumerate → find misconfig → abuse | Identical. WinPEAS is literally LinPEAS for Windows (same PEASS-ng project you already use). |
| Reading scripts/configs before exploiting | Transfers directly (PowerShell scripts, service binaries, scheduled tasks) |
| Cron / systemd-timer running as root → privesc | **Scheduled Tasks / Services running as SYSTEM** — same concept. Unquoted service paths + weak service perms = the Windows version of "writable script run as root." |
| GTFOBins | **LOLBAS** (lolbas-project.github.io) + **WADComs** (wadcoms.github.io) — same concept, same workflow. Instant home. |

**Translation: your entire offensive *mindset* carries over. Only the OS-specific mechanics and the AD layer are new.**

---

## What's GENUINELY NEW (spend your focus here)

### 1. OS mechanics (small — an afternoon of vocabulary)
- **Shell:** learn PowerShell, not cmd. It's Windows' bash but object-oriented. `Get-Content` = `cat`, `Get-ChildItem`/`gci` = `ls`, etc. Grab a one-page cheat sheet.
- **Filesystem:** `C:\`, backslashes, drive letters, `%APPDATA%`. No `/etc/passwd`.
- **Privilege model:** the goal is **SYSTEM** (the root-equivalent). Local Admin ≠ Domain Admin. UAC, integrity levels, and **tokens** exist.
- **The one new local-privesc family with no Linux analog:** **token impersonation** — `SeImpersonatePrivilege` → the "Potato" attacks (JuicyPotato/PrintSpoofer/GodPotato). Service accounts often have it; it hands you SYSTEM. Learn this pattern, it's everywhere on standalone boxes.

### 2. The authentication model (the real new core)
This is the concept that has *no clean Linux equivalent* — give it real attention:
- **NTLM hashes** — you can authenticate with the *hash itself*, no plaintext needed → **pass-the-hash**.
- **NetNTLMv2** — challenge/response you can capture (Responder) and crack or relay.
- **Kerberos** — ticket-based. TGT (Ticket Granting Ticket) → TGS (service tickets). You can pass-the-ticket, and abuse it for the roasting attacks below.

### 3. Active Directory (the actual new continent)
A central LDAP directory of users/computers/groups, run by a **Domain Controller (DC)**. Everything authenticates against it. **You attack the *graph of relationships*, not just individual boxes.** That's the mindset shift.

Canonical AD attack toolkit to learn, roughly in order:
- **Enumeration:** netexec (`nxc`, the crackmapexec successor), ldapsearch, enum4linux-ng, rpcclient, null sessions.
- **Password spraying** (your cred-reuse instinct, weaponized at domain scale).
- **AS-REP roasting** — users without Kerberos pre-auth → crackable hash (`impacket-GetNPUsers`).
- **Kerberoasting** — request service tickets, crack offline (`impacket-GetUserSPNs`).
- **BloodHound** — collect the graph with SharpHound/bloodhound.py, *visually find the path to Domain Admin*. This is the signature AD tool and the core mindset.
- **ACL abuse** (GenericAll, WriteDACL…), **delegation** (unconstrained/constrained/RBCD), **DCSync**, **Golden/Silver tickets** — later, once the basics click.
- **ADCS** (certipy) — certificate-based attacks; increasingly the easy win on modern boxes.

Tooling that installs on your existing Linux box (no Windows VM needed to attack):
`impacket`, `netexec`, `bloodhound.py` + BloodHound GUI, `evil-winrm`, `certipy`, `responder`. (Rubeus/mimikatz run *on-target* when you have a shell.)

---

## The roadmap (where to begin)

### Phase 0 — Setup + survival (1 day)
- Internalize: "I attack from Linux." Install the toolkit above (all apt/pip).
- One-page PowerShell + cmd cheat sheet. Learn the new port map (445/139/88/389/636/3268/5985/3389/135).

### Phase 1 — Standalone Windows boxes (no AD yet)
Goal: get comfy with the OS + local privesc *before* adding domain complexity.
Learn: SMB enum, web-to-foothold on IIS, evil-winrm, WinPEAS, token/Potato privesc, unquoted service paths.
**HTB starter boxes (old, easy, AD-free):** Blue (EternalBlue/MS17-010 — trivial, teaches the flow), Legacy, Devel, Optimum, Jerry, Arctic, Love, Access.

### Phase 2 — Intro AD (the real meat)
Goal: one or two AD concepts per box. **Learn BloodHound here.**
**The beginner-AD trinity on HTB:** **Forest** (AS-REP roast → DCSync — the canonical first AD box), **Active** (GPP cpassword → Kerberoast), **Sauna** (AS-REP roast → autologon creds → DCSync).

### Phase 3 — Full AD chains
Multi-machine, BloodHound path-finding, lateral movement (pass-the-hash/ticket), delegation, ADCS. CPTS/OSCP territory. HTB harder AD boxes + ProLabs.

### The one resource to anchor everything
**TJ Null's OSCP-prep list** — the community-standard curated set of HTB/PG boxes in sensible order, with the Windows/AD progression built in. If you follow one external roadmap, follow that. Pair with HTB Academy's "Active Directory Enumeration & Attacks" module if you want structure.

---

## 2e note to self
The new surface is *small and bounded*: OS vocabulary (cheap), the auth model (one real new idea), and AD graph-thinking (one real new idea). Everything else is your existing methodology re-skinned. Anchor each new thing to its Linux equivalent in the transfer table above and the overwhelm collapses. You're not learning a field — you're learning two concepts and a new dialect.

*And re: the season — you won't clear the Windows boxes this round, and that's fine. Forest is a weekend. You'll be doing intro-AD boxes faster than you think, because the hard part (methodology) is already done.*
