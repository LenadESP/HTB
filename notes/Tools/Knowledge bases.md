A living index of external references, repos, and tools I use throughout my HTB journey. Each entry links out to the actual resource and has a short explanation of when and why to use it.

---
## Table of Contents
- [[Knowledge bases#PayloadsAllTheThings|PayloadsAllTheThings]]: Payload reference for common vuln types

---
## PayloadsAllTheThings
**Link:** [github.com/swisskyrepo/PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)

A community-maintained repo of payloads and techniques for basically every common web and system vulnerability. Each folder is a vuln type with a README explaining the technique and listing ready-to-use payloads.

**When to use it:**

| You found...                        | Go to...                          |
| ----------------------------------- | --------------------------------- |
| XML input being parsed              | `XXE Injection/`                  |
| A template engine (Jinja2, Twig...) | `Server Side Template Injection/` |
| SQL input                           | `SQL Injection/`                  |
| File upload                         | `Upload Insecure Files/`          |
| Command injection point             | `Command Injection/`              |
| SSRF                                | `Server Side Request Forgery/`    |
| JWT token                           | `JSON Web Token/`                 |
| LFI/RFI                             | `File Inclusion/`                 |

> Always read the explanation, not just the payload — understanding why it works matters.