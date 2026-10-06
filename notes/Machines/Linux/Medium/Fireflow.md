# HTB - Fireflow

---
## General Info
- OS: Linux
- Open ports: 22, 443
- Running services: Langflow:flow:80(1.8.2)
- Endpoints: -
- VHosts: flow.fireflow.htb
- Auth: -
- Pwnd date: 06/10/2026

---
## Enumeration  

- Ran nmap, vhost fuzz, etc.
- Found Langflow on vhost flow.fireflow.htb, running version 1.8.2, which is vulnerable to RCE [[CVE-2026-33017]], I'll try a PoC.
- Okay so... I'm seeing a contradiction. Although many articles claim that version 1.8.2 is vulnerable to an unauthenticated RCE attack, the PoC used in the article is asking me for a  JWT token. I'll look further into this issue. Also, I'll fuzz the main page, which I have almost forgotten at this point, jic. Okay. Nothing. I'mma dive in how the PoC works, and why it isn't working.
- Okay yeah that was dumb. It asks for either a JWT token OR a flow id, which we can get from the main page. Now I'm getting an SSL error. I'mma parse the code so that this doesn't happen.
- Well. I'm now getting 403d. Fucking hell.
  
---
## Exploitation  

- HEHEHEH. Ok. Two tricks. One, added debugging to the PoC and guess, only the verification was wrong. Curling my server pinged it.
- Two. Sending the reverse shell over JSON is... complicated. So I hosted a script with the bash shell and just curled it and piped it into bash. Works. I got a foothold as *www-data*. Starting lateral privesc

---
## Lateral PrivEsc

- The only user on the machine that has a shell, besides root, is *nightfall*.
- I seriously hate HTB with my whole fucking heart. Ok, lemme explain. So. I've been enumerating advanced things all day long, whether that's system services, running processes, files, db, etc. And I forgot a command. `env`. Well guess.

(shortened for comfort)
```json
LANGFLOW_SUPERUSER_PASSWORD=n1ghtm4r3_b4_n1ghtf4ll
LANGFLOW_SECRET_KEY=XgDCYma6JZzT3XXyePTbr4vgWrrZ4Vzz-PCQ4PXfKgE
```

- And, guess who's password is n1ght...? Nightfall's. `nightfall:n1ghtm4r3_b4_n1ghtf4ll`
- Got user flag, starting privesc.
  
---
## PrivEsc

-  Ok, so first things (obviously) read the whole user folder of Nightfall, and found the file *./mcp/config.json*:
  
```json
{
  "server": "http://10.129.68.195:30080",
  "status_endpoint": "/api/v1/version",
  "user": "langflow-bot",
  "password": "Langfl0w@mcp2026!"
}
```

> Little explanation before going into this: The machine, while being *www-data*, had already given me many hints towards Kubernetes being the privesc. It seems like it is gonna be it, since that endpoint is a pod in Kubernetes. For more about this, [[Kubernetes]]

- Ok, so I obviously did a GET req to that endpoint, and this is what I got back:

```json 
  {"service":"MCP AI Tool Registry","version":"0.1.0","auth":{"type":"JWT","header":"Authorization: Bearer <token>","supported_algorithms":["HS256","none"]},"docs":"/docs","endpoints":["POST /mcp                        [MCP JSON-RPC 2.0]","POST /api/v1/auth","GET  /api/v1/tools","POST /api/v1/tools               [admin]"]}
```

- This has many things I wanna try that I will, and then I'll report back. Posted the Auth endpoint and got a bearer token, I'll list the tools now, and try to decrypt the token.
  
Well lol. `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJsYW5nZmxvdy1ib3QiLCJyb2xlIjoidXNlciJ9.RenGdHutrKPCOWjwYSJex8C_uMSmy7I8AMkhmTwf9Ps`.

This being the token, this is the plaintext token:

```json
{  
"sub": "langflow-bot",  
"role": "user"  
}
```

- So yeah, obviously I forged a token with the role admin. Let's see what the API says about it.
- Yeah this was a hassle. To summarize, we've read all fucking schemas and docs (like mfs), and have created a tool after forging the token WITHOUT signing or encrypting it. Let's see if we got RCE (Because the tool creating has a field that let's you put code snippets). 

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "uid=1000(mcp) gid=1000(mcp) groups=1000(mcp)\n\n"
      }
    ],
    "isError": false
  }
}

```

- We got RCE in the pod BABYYY!!!! Ok. Let's get a [[Reverse Shell|RS]], I'm done with ts.
- LET'S GOOO. I got a reverse shell using the python shell. (sorry HTB I might've created 10 tests XD). Let's see what this pod's got.
- Ok. well. fuck. false alarm, no RS, BUT, I got idk what key that claude told me to steal and I'mma learn what I wanna use that shit for. It says that I don't need a rs...
- Okay yeah so I basically got the kubernetes token, which can help me login to the K8 API. If the token is decrypted, this is what it says (I won't paste the whole ass token, it's long as fuck)

```json
{
  "aud": ["https://kubernetes.default.svc.cluster.local", "k3s"],
  "kubernetes.io": {
    "namespace": "default",
    "node": {"name": "fireflow"},
    "pod": {"name": "mcp-server-..."},
    "serviceaccount": {"name": "mcp-sa"}
  },
  "sub": "system:serviceaccount:default:mcp-sa"
}

```

- Basically, I'm *mcp-sa* in *default*. Let's see what permissions I have.

```json
{
  "kind": "SelfSubjectRulesReview",
  "apiVersion": "authorization.k8s.io/v1",
  "metadata": {},
  "spec": {},
  "status": {
    "resourceRules": [
      {
        "verbs": [
          "get"
        ],
        "apiGroups": [
          ""
        ],
        "resources": [
          "nodes/proxy"
        ]
      }
```

- Ok, I've omitted the default health and all of those shitty APIs that I don't care about, this permission is the most and only interesting one. What it let's me is basically talk with Kubelet, that's basically the one that manages all pods. That's very, very interesting. Let's see what I can do with kubelet.
- Okay. So I requested the /pods endpoint, that let's me see which pods exist, and holy. The 4th one is literally screaming to be rooted lol. To summarize:

> holy. fuck.

- Ok. So. Where do I begin. Umm the thing is, this pod could mount and bind / on /host/root. Basically mount the whole filesystem. But getting to execute code on that pod was... messy as mother fucking fuck. Take in account that I had an RCE primitive on a mcp server that talked with Kubelet than then talked with the pod. So, to summarize, I read a writeup to see what the implementation of talking with the pod was. Why? Because I did not have permissions to POST on /run. But I did have permissions to do connect to websockets. The /exec endpoint in Kubelet let's you execute commands on pods, but using websockets, and I was both too tired and too bad at python to even attempt writting a script there. So I just stole the writeup's implementation to talk to the websocket, wrapped it in base64 as a script, and made my primitive then execute it on the pod, and I got RCE on the pod.
- Got root flag.

---
## Rabbit holes

 -  Too many to even remember.

---
## Attack chain

- Exploit CVE-2026-33017 (Langflow 1.8.2 RCE) with a flow id; host a bash script and curl-pipe it -> foothold as `www-data`. 
- -Read `env` -> `LANGFLOW_SUPERUSER_PASSWORD` reused as `nightfall:n1ghtm4r3_b4_n1ghtf4ll`. 
- Log in as `nightfall` (reused creds). Get user flag. 
- Read `~/.mcp/config.json` -> MCP Tool Registry creds `langflow-bot:Langfl0w@mcp2026!`. 
- Auth to MCP API, forge an `admin` JWT with `alg:none` (unsigned). 
- Abuse admin tool-registration (`code` field) -> blind RCE in the `mcp-server` pod as `mcp-sa`. 
- Steal pod SA token from `/var/run/secrets/kubernetes.io/serviceaccount/token`. 
- SelfSubjectRulesReview -> only `get` on `nodes/proxy`. 
- GET `nodes/fireflow/proxy/pods` -> spot `node-exporter`: privileged, runAsUser 0, hostPath `/` at `/host/root`. 
- No POST to kubelet `/run`, but `/exec` reachable direct on `:10250` via `v4.channel.k8s.io` websocket with the SA token. 
- Base64 a websocket-exec script, stage to `/tmp` via the MCP primitive, run as root in node-exporter. 
- `cat /host/root/root/root.txt` via the host bind mount. Get root flag.

---
## Learnt

- Too much. Like. The whole Kubernetes stack lol.
  
---
## Notes  
- Machine rating: Hard as FUCK.
  
  