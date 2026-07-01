## What it is

DirtyFrag is a local privilege escalation chain in the **Linux kernel** that combines two vulnerabilities — **CVE-2026-43284** and **CVE-2026-43500** — to take any unprivileged local user to **root** on most modern distributions. It also enables **container escape**.

Both bugs live in the kernel's networking stack, specifically in how it handles **skb (socket buffer) fragments that are backed by externally-owned pages**. When userspace uses `splice()`/`MSG_SPLICE_PAGES` to attach pipe pages to a UDP socket, those pages are shared, not privately owned by the skb. The kernel is supposed to mark such fragments `SKBFL_SHARED_FRAG` so later code makes a private copy (COW) before modifying the data. It didn't, in two separate paths:

- **CVE-2026-43284 (xfrm/ESP):** The IPv4/IPv6 datagram append paths failed to set `SKBFL_SHARED_FRAG` when splicing pages into UDP skbs. An ESP-in-UDP packet built from shared pipe pages then looked like an ordinary uncloned nonlinear skb, so ESP input took the **no-COW fast path and decrypted in place** over memory the skb doesn't privately own.
- **CVE-2026-43500 (rxrpc):** The DATA/RESPONSE handlers only linearized/copied the skb when `skb_cloned()` was true. An skb that wasn't cloned but carried externally-owned paged fragments fell through to **in-place decryption**, binding the shared frag pages directly into the AEAD/skcipher scatter-gather list.

Chained, these give a controlled **out-of-bounds / write-what-where** primitive (CWE-787 / CWE-123) against kernel memory, which is what the exploit turns into root.

---
## Impact

- **Local privilege escalation to root** from any unprivileged user.
- **Container escape** — the same primitive crosses the container boundary because it's a kernel-level bug, not a userspace one.
- CVSS 3.1: CVE-2026-43284 rated **8.8 HIGH** (kernel.org), CVE-2026-43500 rated **7.8 HIGH**. Both scope-changing memory-corruption bugs in the kernel network stack.
- Full system compromise: read/modify/delete anything, execute arbitrary code in kernel context.

---
## Affected versions

- **Linux kernel > 5.3 up to (excluding) 6.18.29**
- **Kernel 6.19 up to (excluding) 7.0.6**
- Plus 7.1-rc1 / 7.1-rc2
- Patched in the stable trees at/after those cutoffs. Fix = extend the "unshare" gate to also copy when `skb_has_frag_list()` or `skb_has_shared_frag()` is true, preserving the zero-copy fast path only for kernel-private frags (NIC page_pool RX, GRO).

---
## Exploitation steps (high-level)

1. Confirm the target kernel is in the vulnerable range (`uname -r`). This is the single cheap check that decides whether DirtyFrag is even on the table.
2. Get an unprivileged local shell on the target (or inside a container you want to escape from).
3. Run the DirtyFrag exploit binary. It uses `splice()`/`MSG_SPLICE_PAGES` into a UDP socket to plant externally-owned shared frags, then drives them through the ESP (43284) and/or rxrpc (43500) in-place-crypto paths to trigger the OOB write against kernel memory.
4. The exploit converts the memory-corruption primitive into a privilege escalation (typically overwriting credentials / a function pointer) and drops a **root shell**.

> This is a **kernel exploit** — on HTB it's usually the _unintended_ path. If a clean intended privesc exists for the box's difficulty tier, prefer it. DirtyFrag is heavy machinery; only reach for it when the box's kernel is in range and no cleaner path presents itself.

---
## PoC

- https://github.com/V4bel/dirtyfrag

**Real example ([[Snapped]]):**

- Snapped ran kernel `6.17.0-19-generic` (Ubuntu 24.04) — inside the vulnerable range.
- After landing as user `jonathan` via SSH, the intended privesc path was well out of range of my current knowledge.
- Used the DirtyFrag PoC to chain CVE-2026-43284 + CVE-2026-43500 → instant root. First time using a kernel-level privesc chain.
- Honest note: I do **not** fully understand the internals of this chain yet — it was above my level. Worth revisiting once I've got more kernel/memory-corruption fundamentals down.