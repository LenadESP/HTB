### What is it

**JWT (JSON Web Token)** – A compact token format used for authentication and authorization.  
**JWE (JSON Web Encryption)** – An encrypted version of JWT (the payload is encrypted).  
**JWKS (JSON Web Key Set)** – A set of public keys (in JSON format) that clients use to verify JWT signatures.

---

### What it does

- **JWT** – Carries claims (e.g., `{"user":"admin", "role":"admin"}`) signed with a secret or private key. Server verifies the signature to trust the claims.
- **JWE** – Encrypts the JWT so the payload cannot be read without the decryption key.
- **JWKS** – Exposes public keys (usually RSA or EC) so clients can verify JWT signatures without hardcoding keys.

---
### JWT Structure

`header.payload.signature` (base64url encoded)
- **Header** – Algorithm (`HS256`, `RS256`, etc.) and type (`JWT`).
- **Payload** – Claims (user data, expiry, etc.).
- **Signature** – Verifies the token hasn't been tampered with.

---
### Common Attacks

1. **None algorithm attack** – Change header to `{"alg":"none"}` and remove signature. Some old libraries accept it.

2. **RS256 to HS256 confusion** – If server expects RS256 (asymmetric) but you send HS256 (symmetric), you can sign the token using the public key (which you have).
 
3. **Weak secrets** – HS256 tokens can be brute-forced if the secret is weak.

4. **JWE misuse** – If the server uses a public key to encrypt (instead of private key), you can decrypt it if you have the public key ([[CVE-2026-29000]]).

5. **JWKS injection** – If the server allows you to provide a malicious JWKS URL, you can control the verification key.

---
### Key Files / Concepts

|Term|Meaning|
|---|---|
|`HS256`|Symmetric signing (shared secret)|
|`RS256`|Asymmetric signing (private key signs, public key verifies)|
|`JWE`|Encrypted JWT (hides payload)|
|`JWKS`|Endpoint like `/api/auth/jwks` that returns public keys|

---

# Tools
### Decode JWT (without verification)
```bash
jwt decode <token>

# Crack HS256 secret with hashcat
hashcat -m 16500 <jwt.txt> rockyou.txt

# Forge JWT with python
python -c "import jwt; print(jwt.encode({'user':'admin'}, 'secret', algorithm='HS256'))"
```
