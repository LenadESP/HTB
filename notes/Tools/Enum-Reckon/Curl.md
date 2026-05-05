### What is it
`curl` is a command-line tool for transferring data over networks. It supports HTTP, HTTPS, FTP, and many other protocols. It's the Swiss Army knife for testing APIs and web servers.

---
### What it does

- Sends HTTP requests (GET, POST, PUT, DELETE, etc.)
- Downloads/upload files
- Sets custom headers, cookies, user agents
- Handles authentication (Basic, Bearer tokens)
- Works with JSON, form data, multipart files
- Follows redirects, handles SSL certificates

---

### Common Options (Parameters)

|Option|What it does|
|---|---|
|`-X` or `--request`|HTTP method (GET, POST, PUT, DELETE, etc.)|
|`-H`|Add a header (repeat for multiple)|
|`-d`|Send data in request body (POST by default)|
|`-b`|Send cookies (e.g., `-b "name=value"`)|
|`-c`|Save cookies to file|
|`-o`|Save output to file|
|`-O`|Save output using remote filename|
|`-L`|Follow redirects|
|`-k`|Ignore SSL certificate errors (insecure)|
|`-v`|Verbose output (show request/response headers)|
|`-i`|Include response headers in output|
|`-I`|Fetch only headers (HEAD request)|
|`-u`|Basic authentication (`user:pass`)|
|`-A`|Set User-Agent|
|`-e`|Set referer URL|
|`-F`|Send multipart form (file upload)|
|`-x`|Use proxy (`http://proxy:port`)|

---

### Typical JSON Usage

**1. GET request**

```bash
curl https://api.example.com/users
```


**2. POST JSON data**
```bash
curl -X POST https://api.example.com/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}'
```
bash

**3. PUT JSON**
```bash
curl -X PUT https://api.example.com/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"New Name"}'

```

**4. DELETE**
```bash
curl -X DELETE https://api.example.com/users/1
```

**5. With Bearer token**
```bash
curl -H "Authorization: Bearer eyJhbGciOi..." https://api.example.com/protected
```

**6. Save output to file**
```bash
curl -o output.json https://api.example.com/data
```

**7. Verbose + follow redirects**
```bash
curl -L -v https://target.com/path
```

---
### Notes
- If you don't specify `-X`, GET is the default.
- When you use `-d`, POST is automatically assumed; you don't need `-X POST`.
- For JSON, always set `Content-Type: application/json`.
- To pretty-print JSON responses, pipe to `jq` (if installed): `curl ... | jq`
- Use `-k` for self-signed certificates (but avoid in production).
- For large file uploads, use `-F` instead of `-d` (multipart).