# HTB - Machine

---
## General Info

- OS: Linux
- Open ports: 80, 22
- Running services: Ssh (9.2p1), nginx (1.22.1)
- Endpoints:
	- /services
	- /tools/variable-font-generator
		- /process (POST)
- VHosts: portal.variatype.htb
	- Endpoints:
		- /files (401)
- Auth: No auth
- Pwnd date: -

---
## Enumeration  

- After running [[Nmap]] and [[FFuF]] to fuzz endpoints and VHosts, discovered open services and no VHosts or enpoints besides the ones on the main page.  
- After seeing the Website's functionality, assumed that the server is handleling XML files insecurely, based on this POST req and response:

REQ (info removed for simplicity)
```HTTP
POST /tools/variable-font-generator/process HTTP/1.1
Host: variatype.htb
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate, br
Referer: http://variatype.htb/tools/variable-font-generator
Content-Type: multipart/form-data; boundary=----geckoformboundary1c0c771b9f021d1294c950eece129a69
Content-Length: 775
Origin: http://variatype.htb
DNT: 1
Connection: keep-alive
Upgrade-Insecure-Requests: 1
Sec-GPC: 1
Priority: u=0, i

------geckoformboundary1c0c771b9f021d1294c950eece129a69
Content-Disposition: form-data; name="designspace"; filename="README.txt"
Content-Type: text/plain
------geckoformboundary1c0c771b9f021d1294c950eece129a69
Content-Disposition: form-data; name="masters"; filename="README.txt"
Content-Type: text/plain
------geckoformboundary1c0c771b9f021d1294c950eece129a69--
```

RESPONSE
```HTTP
HTTP/1.1 302 FOUND
Server: nginx/1.22.1
Date: Mon, 27 Apr 2026 09:53:29 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 247
Connection: keep-alive
Location: /tools/variable-font-generator
Vary: Cookie
Set-Cookie: session=eyJfZmxhc2hlcyI6W3siIHQiOlsiZXJyb3IiLCJUaGUgbWFpbiBmaWxlIG11c3QgYmUgYSB2YWxpZCAuZGVzaWduc3BhY2UgZG9jdW1lbnQuIl19XX0.ae8yGQ.7RwjtDlaPhdLTYoJbcTxuTo_EU4; HttpOnly; Path=/

<!doctype html>
<html lang=en>
<title>Redirecting...</title>
<h1>Redirecting...</h1>
<p>You should be redirected automatically to the target URL: <a href="/tools/variable-font-generator">/tools/variable-font-generator</a>. If not, click the link.
```

DECODED COOKIE:
```JSON
{
    "_flashes": [
        {
            " t": [
                "error",
                "The main file must be a valid .designspace document."
            ]
        }
    ]
}
```
- Well maybe I need to understand the page first. I'm gonna try to upload a simple designspace and ttf file.
- I hate this shit. I came back 2 days after and now I did find a VHost. I'm gonna enumerate it.

---
## After much enumerating, I gave up. I searched a writeup, and it said that a CVE existed in the library python used to parse the files. The version of the library was supposed to be retrieved from a exposed .git repo in the portal vhost. I did not find that in my enumeration, nor I have the skills to do so. Given this, I will stop continuing doing this machine, because from here on this machine is not "learning" anymore, and I am not showing my skills, but rather just copying.
