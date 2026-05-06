# HTB - Machine

---
## General Info
- OS: Linux
- Open ports: 22, 80, 5000 (localhost)
- Running services: [[SSH (Secure Shell)|SSH]] (8.9p1), nginx (1.18.0)
- Endpoints:
	- /about
	- /upload
	- /static/
		- /css
		- /images
		- /uploads
	 - /upload-cover
- VHosts: -
- Auth: -
- Pwnd date:

---
## Enumeration  

- [[Enum.sh]] broke, ran basin enumeration on my own.
- Found an email: submissions@tiempoarriba.htb
- Following guided mode tasks (because I was very lost, didn't know where to beggin)

> Guided mode pointed me towards finding an enpoint that *can cause the server to generate an outbound HTTP request*

- I learnt about [[SSRF (Server-Side Request Forgery)|SSRF]] with guided mode. /upload-cover takes a url as a parameter. I can do something with that.

---
## Exploitation  

> A little explanation before continuing: Basically, when you upload an image to the /upload-cover endpoint (which is used for uploading book covers), it can take both a file or a URL. So if you decide to POST a URL, you can point to every URL you want, even to `http://localhost`.
> This is [[SSRF (Server-Side Request Forgery)]], and allows the following to happen:

- The server doesn't answer to `http://localhost` but it does to `http://localhost:8080` with a placeholder image. Since port 8080 (which doesn't run anything) just gives back a placeholder image, I can asume that running services time out (probably because the backend is expecting an image), while non open ports don't.

- Since the server only hangs when accessing ports that are being used (such as port 80 when requested on localhost), I'll try to probe it with a [probing script](SSRFProbing.sh), to see if there's any service running in localhost (again, guided mode pointed me towards it). 

- Okay. So. I got port 5000. It gives back the reponse (to the request made to localhost) as a binary file. This file can be located in the path the main page answers when making the request, so I crafted a [script](ServerEnumeration.sh) to automatize enum. I'll enumerate this localhost service.

- Wow a lot happened in a short period of time. Better seen than explained:
  
```json
path> /api
{"messages":[{"promotions":{"description":"Retrieve a list of all the promotions in our library.","endpoint":"/api/latest/metadata/messages/promos","methods":"GET"}},{"coupons":{"description":"Retrieve the list of coupons to use in our library.","endpoint":"/api/latest/metadata/messages/coupons","methods":"GET"}},{"new_authors":{"description":"Retrieve the welcome message sended to our new authors.","endpoint":"/api/latest/metadata/messages/authors","methods":"GET"}},{"platform_use":{"description":"Retrieve examples of how to use the platform.","endpoint":"/api/latest/metadata/messages/how_to_use_platform","methods":"GET"}}],"version":[{"changelog":{"description":"Retrieve a list of all the versions and updates of the api.","endpoint":"/api/latest/metadata/changelog","methods":"GET"}},{"latest":{"description":"Retrieve the last version of api.","endpoint":"/api/latest/metadata","methods":"GET"}}]}

path> /api/latest/metadata/messages/authors
{"template_mail_message":"Welcome to the team! We are thrilled to have you on board and can't wait to see the incredible content you'll bring to the table.\n\nYour login credentials for our internal forum and authors site are:\nUsername: dev\nPassword: dev080217_devAPI!@\nPlease be sure to change your password as soon as possible for security purposes.\n\nDon't hesitate to reach out if you have any questions or ideas - we're always here to support you.\n\nBest regards, Editorial Tiempo Arriba Team."}
```

- [[SSH (Secure Shell)|SSHed]] to the server using user "dev" and password "dev080217_devAPI!@".
- Got user flag. Starting PrivEsc

---
## PrivEsc

- Found git repo in /home/dev/apps
- Also found prod user under /home/prod
- While navigating git, I checked git history (by running `git logs --oneline`), and found several commits:
```git
dev@editorial:~/apps$ git log --oneline
8ad0f31 (HEAD -> master) fix: bugfix in api port endpoint
dfef9f2 change: remove debug and update api port
b73481b change(api): downgrading prod to dev
1e84a03 feat: create api to editorial info
3251ec9 feat: create editorial app
```
- After reviewing them, `b73481b` caught my eye because of the commit message, because it was downgrading prod to dev, which meant that any commit before that could contain valuable information to login as *prod*.
- So I rollbacked to the version prior to it (`git checkout 1e84a03`), in hopes that it would give me a way to get to *prod* user.
- Bingo. Found the next message on /home/dev/apps/app_api/app.py:

>"Welcome to the team! We are thrilled to have you on board and can't wait to see the incredible content you'll bring to the table.\n\nYour login credentials for our internal forum and authors site are:\nUsername: prod\nPassword: 080217_Producti0n_2023!@\nPlease be sure to change your password as soon as possible for security purposes.\n\nDon't hesitate to reach out if you have any questions or ideas - we're always here to support you.\n\nBest regards, "

- I'm *prod* after doing `su prod` and using credentials gathered from that message.

---

- Well. Umm ok step by step:
- Basically, I enumerated my permissions again, now under user *prod*, and when running sudo -l (files I can execute as root), amongst others, I got this file I could execute as root:

```linux
(root) /opt/internal_apps/clone_changes/clone_prod_change.py *
```

- The first thing that caught my eye was the script: 
`/opt/internal_apps/clone_changes/clone_prod_change.py`, so I went to check it:

```python
#!/usr/bin/python3

import os
import sys
from git import Repo

os.chdir('/opt/internal_apps/clone_changes')

url_to_clone = sys.argv[1]

r = Repo.init('', bare=True)
r.clone_from(url_to_clone, 'new_changes', multi_options=["-c protocol.ext.allow=always"])
```
- After asking Claude (I don't know or want to know Python tbh), the flag "-c protocol.ext.allow=always" allowed me to pass an `ext::` flag to the script, and since whatever I inputed to the script automatically became the requested URL, it allowed me to pass a script that made the python script execute `chmod +s /bin/bash`, which effectively allowed me to execute /bin/bash and get the root profile with the flag -p, allowing me to execute commands as root.

> A little of explanation of why this happened. There were 3 factors:
> 	1. I could run the script as sudo 
> 	2. The "-c protocol.ext.allow=always" flag allowed me to pass a `ext::` flag, making git execute a command (as the script's owner) that isright next to the `ext::` flag, as shown here: `ext::command arg1 arg2`. This is because some apps require command execution before resolving the host, which is a feature I exploited.
> 	3. All input passed by the user was unsanitized.
> 	   
> Another matter is the fact that I had to use a script that chmodded /bin/bash because git didn't seem to be able to resolve it directly, so I passed a script as an argument.


- Got root flag.

---
## Rabbit holes

 - None (surprisingly)
---
## Attack chain

- Exploit SSRF vulnerability in parameter "bookurl" in endpoint /upload_cover using POST method to probe for localhost services.
- Enumerate service running on port 5000.
- Get default credentials under  endpoint `/api/latest/metadata/messages/authors`
- Get user flag.
- Discover git repository in /home/dev/apps, and rollback to get *prod* user's credentials.
- Login as user *prod*
- Find the script you can run as sudo, `/opt/internal_apps/clone_changes/clone_prod_change.py`
- Read the code and exploit the Git Protocol Vulnerability explained before to force git to make /bin/bash SUID, giving you root.
- Get root flag.

---
## Notes  
- Machine rating: Mediumish/easy
- This machine was cool as fuck.

---
## Learnt:
- [[SSRF (Server-Side Request Forgery)]] exploits
- Git Protocol Vulnerability