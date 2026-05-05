### What is it

Jetty is a lightweight, pure Java HTTP server and Servlet container. It's often embedded in applications (like Spring Boot) rather than run standalone.

---

### What it does

- Serves HTTP (web pages, APIs, static files)
- Runs Java servlets and JSPs
- Supports WebSockets, HTTP/2, and HTTP/3
- Handles machine-to-machine communication in software frameworks

---
### Key Features

| Feature             | What it means                                                |
| ------------------- | ------------------------------------------------------------ |
| **Embeddable**      | Can be run inside your code, no separate installation needed |
| **Lightweight**     | Smaller memory footprint than Tomcat                         |
| **Servlet support** | Implements the Jakarta EE Servlet specification              |
| **HTTP/2 ready**    | Supports modern web protocols                                |

---
### Common Misconfigurations (What to look for)

1. **WEB-INF access via encoded paths** – Default behavior may allow accessing `WEB-INF/web.xml` using `%2e` or `%2e%2e` segments in the URL.
2. **Version disclosure** – Relying on self-reported version numbers may lead to false security assumptions. Look for `X-Powered-By: Jetty` headers or default error pages.
3. **Default handler leaks context paths** – The `DefaultHandler` at the end of the handler tree can list all configured contexts when hitting a 404.
4. **ThreadLocal authentication issues** – Under certain conditions, authentication information may persist across requests (`JASPIAuthenticator` flaw).

---

### How to Exploit (Common hacks)

|Attack|What to do|
|---|---|
|**Access WEB-INF**|Request `/context/%2e/WEB-INF/web.xml` to retrieve config files|
|**Path traversal (old versions)**|Use `%2e%2e%5c` (encoded `..\`) in URL (Jetty 6.x only)|
|**Information disclosure**|Hit a non-existent path to see the `DefaultHandler` listing all apps|
|**Check version**|Look at response headers or error pages to identify version and known CVEs|

---
# Payloads/reckon

```bash
# Check for Jetty version in headers
curl -I http://target:8080

# Fuzz for WEB-INF access
ffuf -w /path/to/wordlist.txt -u http://target:8080/context/FUZZ

# Look for default handler leak
curl http://target:8080/notexist
```
