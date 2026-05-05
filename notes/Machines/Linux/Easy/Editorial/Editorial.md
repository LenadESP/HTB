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
- VHosts
- Auth:
- Pwnd date:

---
## Enumeration  

- [[Enum]] broke, ran basin enumeration on my own.
- Found an email: submissions@tiempoarriba.htb
- Following guided mode tasks (because I was very lost), I learnt about SSRF. /upload-cover takes a url as a parameter. I can do something with that.

---
## Exploitation  

> A little explanation before continuing: Basically, when you upload an image to the /upload form (which is used for uploading books), it takes both a file or a URL. So in the URL, you can point to every place, even to `http://localhost`, which enables the following:

- The server doesn't answer to `http://localhost` but it does to `http://localhost:8080` with a placeholder. Which means that running services time out (probably because the backend is expecting an image).

- Since the server only hangs when accessing ports that are being used (such as port 80 when requesting only localhost), I'll try to probe it with a [probing script](./SSRFProbing.sh), to see if there's any service running in localhost (again, guided mode pointed me towards it). 

- Okay. So. I got port 5000. It gives back the reponse (to the request made to localhost) as a binary file in the path the server answers when making the request, so I crafted a [script](./ServerEnumeration.sh) to automatize enum (since I need to download the file to get the answer). I'll enumerate this service.

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

-  

---
## Rabbit holes

 - 

---
## Attack chain

- 

---
## Notes  
- Machine rating: