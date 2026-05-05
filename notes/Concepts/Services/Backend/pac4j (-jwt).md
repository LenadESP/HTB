### What is it

pac4j is a Java security framework that handles authentication and authorization.  
The `pac4j-jwt` module adds JWT generation, validation, and encryption support.

---

### What it does

- Generates JWT tokens from user profiles (`JwtGenerator`).
- Validates JWT tokens (`JwtAuthenticator`).
- Supports plain JWT, signed JWT (RS256, HS256, etc.), and encrypted JWT (JWE).

---

### Common Attacks

1. **[[CVE-2026-29000]]** – `JwtAuthenticator` incorrectly allows JWE tokens encrypted with the server's public key. An attacker can forge a token with arbitrary claims, bypassing authentication.
2. **RS256 → HS256 confusion** – If server expects RS256 but accepts HS256, use the exposed RSA public key as a symmetric secret.
3. **Weak HS256 secret** – Bruteforce offline with hashcat.
4. **`none` algorithm attack** – Change `alg` to `none` and remove signature.
5. **Misconfigured JWKS** – If you can trick the server into accepting a malicious JWKS endpoint, you can control signature verification.

---

### Detection

- HTTP header `X-Powered-By: pac4j-jwt/6.0.3`.
- Cookie named `pac4jJwtToken`.
- `Authorization: Bearer <token>` with a JWT or JWE.
- Exposed `/jwks` endpoint.
- Error pages mentioning `pac4j`.

---

# Payloads/reckon/crack
```bash
# Decode JWT (cannot decode JWE without key)
jwt decode <token>

# Crack HS256 secret
hashcat -m 16500 jwt.txt rockyou.txt
```
