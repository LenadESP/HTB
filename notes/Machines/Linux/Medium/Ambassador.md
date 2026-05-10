# HTB - Ambassador

---
## General Info
- OS: Linux 5.4.0-126-generic, Ubuntu 20.04.5 LTS
- Open ports: 22, 80, 3000, 3306
- Internal ports (127.0.0.1): 8500, 8301, 8302, 8600
- Running services: [[SSH (Secure Shell)||SSH]]:22 (8.2p1), Apache:80 (2.4.41), Hugo:80(v0.94.2), MySQL:3306 (8.0.30-0ubuntu0.20.04.2), Grafana:3000 (8.2.0)
- Internal services: Consul:8500:8301:8302:8600 (1.13.2)
- Endpoints:
	- 80:
		- /images (301)
		- /index.html
		- /404.html
		- /tags (301)
		- /tags/
		- /icons/
		- /categories (301)
		- /posts  (301)
		- /server-status
- VHosts: -
- Auth: Grafana's auth (but bypassed entirelly), Consul auth.
- Users: developer and root. 
- Pwnd date: 08/05/2026

---
## Enumeration  

- Ran [[Enum.sh]] and [[Dirsearch - python]] on port 80.
- Besides that, I got into the main page on port 80 and found the next message:

>Welcome to the Ambassador Development Server
   Hi there! This server exists to provide developers at Ambassador with a standalone development environment. When you start as a developer at Ambassador, you will be assigned a development server of your own to use.
   Use the developer account to [[SSH (Secure Shell)||SSH]], DevOps will give you the password.

- This will probably be important later on.
- I also found Grafana on port 3000 with a known path traversal vuln: [[CVE-2021-43798]].
- This path traversal vuln resides in `/plugins/public/alertlist/(path)`, so I will try to enumerate the server this way, to gain as much intel as I can, and hopefully credentials or other interesting things.



---
## Exploitation  

- Got Grafana configuration files, trying to find anything usable or exploitable.
- Got admin password, set to default, "messageInABottle685427" on Grafana config. Got admin access to Grafana.
- Dumped the whole DB of Grafana, but found basically nothing. Config file is empty as well. And there's no RCE exploit. 

> At this point, I was 2H down into a rabbit hole of trying to find Grafana configs, credentials or anything that could be useful at all. I went to the guided mode, and discovered that in path `/etc/grafana/provisioning/datasources/mysql.yaml` (Because that is the DataSource name of the only datasource) (Yeah, kinda dumb missing that. I was feverish yesterday and I did good resting and coming back today. I clocked it instantly), there is a file that contains the following credentials:

```yaml
apiVersion: 1

datasources:
 - name: mysql.yaml 
   type: mysql
   host: localhost
   database: grafana
   user: grafana
   password: dontStandSoCloseToMe63221!
   editable: false
```

- Even tho it clearly says "localhost", I will try to log in on the public facing mysql to see if I they have reused credentials.
- Well. They have reused credentials. After logging into MySQL, I enumerated the databases, and found one that caught my eye: `whackywidget` (since the rest were default and I already had the grafana DB), so I enumerated tables: `users`, selected everything from that table and got this back:

```MySQL
MySQL [whackywidget]> SELECT * FROM users;
+-----------+------------------------------------------+
| user      | pass                                     |
+-----------+------------------------------------------+
| developer | YW5FbmdsaXNoTWFuSW5OZXdZb3JrMDI3NDY4Cg== |
+-----------+------------------------------------------+
```

- This is presumably Base64, so I decoded it on the terminal (echo "" | base64 -d).
- Bingo, got password "anEnglishManInNewYork027468" for user *developer*. Let's try that one in [[SSH (Secure Shell)|SSH]] (remember the main page message?)
- As I had presumed, those were the credentials for [[SSH (Secure Shell)|SSH]]. 
- Got user flag. Starting PrivEsc.

---
## PrivEsc

- Found a weird folder in /, `/development-machine-documentation`, which is hosting the page on port 80, using a framework called "Hugo".  
- Dead end. Found a weird service running as root: `Consul`, in this line (telling me where config is) 
``` bash
root         987  0.1  3.8 795636 76616 ?        Ssl  May07   2:25 
/usr/bin/consul agent 
-config-dir=/etc/consul.d/config.d 
-config-file=/etc/consul.d/consul.hcl
```
- Ok, so I went to the config folder, and there's something interesting about this: the permissions for the folder /etc/consul.d are drwx-wx---. Which means I can write to this folder but not read it... 
- I searched for quite some time around the configs but found mostly nothing. Just ACL active, which meant that I needed a token to auth.
- Well, that was a rabbit hole. Maybe checking /opt/my-app earlier wouldn't have been such a bad idea (since I also checked /opt/consul). 
- Not fully a rabbit hole tho, I got a consul Auth Token (presumably admin/high priv) from /opt/my-app git history (git repo) that got deleted, by using `git log --oneline` and        `git show (id)`. Trying to auth in Consul now.

Ooook this was cool. See this request:

```BASH
curl -X PUT \
  -H "X-Consul-Token: bb03b43b-1d81-d62b-24b5-39540ee469b5" \
  -d '{
    "ID": "pwn",
    "Name": "pwn",
    "Address": "127.0.0.1",
    "Port": 80,
    "Check": {
      "Args": ["/bin/bash", "-c", "chmod +s /bin/bash"],
      "Interval": "10s"
    }
  }' \
  http://127.0.0.1:8500/v1/agent/service/register
```
> Basically, I got the auth token from the git history in the project /opt/my-app, which had been deleted but not from the logs. So, with that token, you can use it to call the API endpoint that "registers" services, and during that, you can ask it to run commands as health checks. You see where this is going? Since Consul is running as root, those "health checks", which get executed periodically, are executed by root, and if you put in that health check the command `chmod +s /bin/bash`, you make /bin/bash SUID, effectively giving you root by running `/bin/bash -p`
> 
- Ran `/bin/bash -p` and got root
- Got root flag.

---
## Rabbit holes

 - Trying to dump Grafana's DB (dead end)
 - Trying PrivEsc on /development-machine-documentation (dead end)
 - Trying to break Consul (also dead end)

---
## Attack chain

- Enumerate page, and exploit Path Traversal in Grafana to get reused MySQL credentials in path `/etc/grafana/provisioning/datasources/mysql.yaml`.
- Retrieve credentials from online MySQL DB on port 3306 to get access to user *developer* on [[SSH (Secure Shell)|SSH]]
- Get user flag.
- Find service *Consul* running on localhost and read configs located in `/etc/consul.d/`. 
- As you read the config, acl is active so you need an auth token
- Find the git project "my-app" located in /opt/my-app, read logs and check last commits, where the token is stored in plain sight.
- Use the API of Consul with the token retrieved from the commit history to create a new "service" that executes `chmod +s /bin/bash` as health checks, which effectively make /bin/bash SUID and let's you run `/bin/bash -p`, becoming root.
- Get root flag.

---
## Learnt

- Quite a lot on chain exploiting. Mainly just how to navigate more complex systems without getting lost, as well as the existence of services such as Consul, MySQL and Grafana, and the exploits that those can lead to. 
- Also learnt that when I'm stuck enumerating Grafana / a CMS / any complex web app, I have to look for _its_ config files via the LFI before going deeper into the app itself. Configs leak creds for adjacent services.
- Services running as root + any "execute script" feature = privesc. Future patterns to recognize: Consul, Salt, Jenkins, Ansible Tower, etc.

---
## Notes  
- Machine rating: Mediumish/hard.
- This machine was also cool af.
  
  