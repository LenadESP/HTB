## What is it

SSRF is an attack where you make the server perform HTTP requests on your behalf. Instead of you requesting a resource directly, the server does it — which means you can reach internal services, localhost ports, and other infrastructure that you can't access from the outside.

---
## How to detect it

- Any parameter that takes a URL as input (`bookurl`, `url`, `webhook`, `redirect`, `fetch`, etc.)
- Endpoints that seem to fetch remote resources (image upload by URL, link preview, PDF generation, etc.)
- Response differs depending on whether the URL exists or not (timeout vs instant response)

---
## How to exploit it

**Port probing** — probe localhost ports to find internal services:

- Open port → server hangs → curl times out
- Closed port → instant response (connection refused)


**Service enumeration** — once you find an open port, interact with it through the server:

```bash
curl -s -X POST http://target.htb/vulnerable-endpoint \
    -F "url=http://localhost:5000/api/users"
```


**Cloud metadata** — on cloud machines try:

```
http://169.254.169.254/latest/meta-data/
```

Often leaks cloud credentials and instance info.

---
## Common targets

- Internal APIs on high ports
- Admin panels bound to localhost
- Cloud metadata endpoints (AWS, GCP, Azure)
- Internal databases
- Other machines on the internal network

---
## Tools/scripts
(Used in [[Editorial]] machine)
- [[SSRFProbing.sh]] — probes localhost ports via timeout detection
- [[ServerEnumeration.sh]] — interactive terminal to enumerate a found internal service