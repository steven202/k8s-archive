# K8s Cluster Usage Guide

## Accessing the Cluster

```bash
ssh <username>@cm.geo.sciclone.wm.edu
```

From off-campus, use the bastion host:
```bash
ssh -J user@bastion.wm.edu user@cm.geo.sciclone.wm.edu
```

## Cluster Status

- Dashboard: https://hpc.wm.edu/grids/
- `getnodestats` — node resource usage (CPU/Memory/GPU per node)
- `getgpuusage` — all running GPU jobs, their age, and GPU type

## Finding Your User/Group IDs

```bash
id -ru    # USER_ID  (cwang33 = 268412)
id -rg    # GROUP_ID (cwang33 = 1133)
```

---

## Best Practices

1. **Use Jobs, not Pods** in personal user namespaces (required since Sept 17, 2025). Pods only in project namespaces (e.g., `wmd3i`).

2. **Always set `securityContext`** with `runAsUser` and `runAsGroup`. Pods rejected without it.

3. **Always set `activeDeadlineSeconds`** (walltime). Default: 86400s (1 day), max: 432000s (5 days).

4. **Set `ttlSecondsAfterFinished`** to control log retention. Default: 3600s (1 hour), max: 604800s (1 week).

5. **Kill Jobs, not Pods.** `kubectl delete job <name>`. Deleting the pod restarts it.

6. **Write outputs to scratch** (`/sciclone/scr10` or `/scr20`). Move to `/sciclone/data10` after. Home quota: 50GB.

7. **No sudo in pods.** The cluster enforces `securityContext`. Pre-install tools via:
   - Custom Docker image (`docker/`) — apt, pip pre-installed at build time
   - NFS home (`/sciclone/home/cwang33`) — standalone binaries persist across pods
   - `pip install --user` / conda environments in home

8. **No `kubectl port-forward` for cwang33.** Use Cloudflare Tunnel inside the pod for external access.

---

## Common Commands

| Command | Purpose |
|---|---|
| `kubectl get pods -n wmd3i` | List pods in namespace |
| `kubectl get jobs` | List your jobs |
| `kubectl logs <pod> -n <ns>` | View pod logs |
| `kubectl describe pod <pod> -n <ns>` | Inspect pod |
| `kubectl apply -f <file>.yaml` | Submit job/pod |
| `kubectl delete -f <file>.yaml` | Tear down |
| `kubectl delete job <name>` | Kill a running job |
| `kubectl delete pod <name> -n <ns>` | Kill a pod |
| `kubectl exec -it <pod> -n <ns> -- /bin/bash` | Shell into pod |
| `getnodestats` | Cluster node usage |
| `getgpuusage` | All GPU jobs |

---

## Three Debug Methods

### 1. Bash Shell — `kubectl exec`

```bash
kubectl apply -f yamls/interactive-bash.yaml
kubectl exec -it test-bash -n wmd3i -- /bin/bash
kubectl delete pod test-bash -n wmd3i
```

Internal only. No external access needed.

### 2. Jupyter Notebook — External via Cloudflare Tunnel

```bash
kubectl apply -f yamls/interactive-note.yaml
# Open: https://k8s-note.disciple.qzz.io
kubectl delete pod test-note -n wmd3i
```

DNS required: `k8s-note.disciple.qzz.io` CNAME → `<tunnel-id>.cfargotunnel.com`

**Alternative: Official JupyterHub** at **https://notebooks.sciclone.wm.edu** (W&M login, no setup needed).

### 3. VS Code (code-server) — External via Cloudflare Tunnel

```bash
kubectl apply -f yamls/interactive-code.yaml
# Open: https://k8s-code.disciple.qzz.io
kubectl delete pod test-code -n wmd3i
```

DNS required: `k8s-code.disciple.qzz.io` CNAME → `<tunnel-id>.cfargotunnel.com`

---

## YAML Files (in `yamls/`)

| File | Kind | Purpose | External Access |
|---|---|---|---|
| `noninteractive-job.yaml` | Job | Batch execution | N/A |
| `interactive-bash.yaml` | Pod | Bash debug shell | No |
| `interactive-note.yaml` | Pod | Jupyter Notebook | Cloudflare tunnel |
| `interactive-code.yaml` | Pod | VS Code (code-server) | Cloudflare tunnel |

All use:
- Namespace: `wmd3i`
- Node: `d3i00.sciclone.wm.edu` (4× NVIDIA L4)
- Toleration: `node=d3i:NoSchedule`
- NFS mount: `/sciclone/home/cwang33`

---

## GPU Types (for `nodeSelector`)

| `nvidia.com/gpu.product` | GPU | Nodes |
|---|---|---|
| `"NVIDIA-L4"` | NVIDIA L4 | d3i00, d3i01 |
| `"NVIDIA-A40"` | NVIDIA A40 | gu07–gu19 |
| `"Quadro-RTX-6000"` | Quadro RTX 6000 | ts4 |
| `"NVIDIA-L40S"` | NVIDIA L40S | aiphys-node1, dsci-he-01, jdserver1 |
| `"NVIDIA-H100-NVL"` | NVIDIA H100 | jdserver2 |
| `"NVIDIA-H200-NVL"` | NVIDIA H200 | ai4scientist-2 |

---

## Directory Structure

```
k8s_archive/
├── yamls/                  # K8s YAML definitions
│   ├── noninteractive-job.yaml
│   ├── interactive-bash.yaml
│   ├── interactive-note.yaml
│   └── interactive-code.yaml
├── docker/                 # Custom Docker image
│   ├── Dockerfile          #   Image definition (apt + pip + code-server + cloudflared)
│   ├── build.sh            #   Local build+push script (requires Docker)
│   └── build.yml           #   GitHub Actions workflow (requires DOCKERHUB_TOKEN secret)
├── scripts/                # Helper scripts
│   └── setup-env.sh        #   Run inside pod to set up conda/pip environment
└── docs/                   # Documentation
    ├── README.md
    ├── k8s_usage_guide.md  #   This guide
    ├── k8s_emails.md       #   Admin emails (policy changes, security context, etc.)
    ├── k8s_example_pod.yaml
    ├── k8s_exmaple_job.yaml
    └── slurm_example
```

---

## Custom Docker Image (`docker/`)

The base pytorch image lacks curl, git, vim, code-server, cloudflared, etc. Building a custom image pre-installs everything so pods start instantly.

**Option A: Build on your Mac**
```bash
docker login -u cwang33
# password: <personal access token>
cd docker && ./build.sh
```

**Option B: GitHub Actions**
1. Add secrets to your GitHub repo: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
2. Copy `build.yml` to `.github/workflows/docker-build.yml`
3. Push — auto builds on Dockerfile changes

After build, uncomment `image: cwang33/k8s-dev:latest` in the YAMLs and remove the download commands.

---

## Key Differences: Pod vs Job

| | Pod | Job |
|---|---|---|
| API version | `v1` | `batch/v1` |
| User namespace | No (since Sept 2025) | Yes |
| Project namespace | Yes | Yes |
| Walltime | No built-in | `activeDeadlineSeconds` |
| Auto-cleanup | No | `ttlSecondsAfterFinished` |
| Interactive shell | Yes | Logs only |
| Use case | Debugging, interactive | Batch execution |

---

## Troubleshooting

- **securityContext error**: Set `runAsUser`/`runAsGroup` from `id -ru`/`id -rg`
- **Pod won't run in user namespace**: Use `kind: Job`, not `kind: Pod`
- **Job restarts after deleting pod**: Delete the Job, not the pod
- **Pending (unschedulable)**: Check node taints — d3i nodes need `tolerations: node=d3i`
- **No port-forward permission**: Use Cloudflare Tunnel in the pod
- **apt-get fails (permission denied)**: No root in pod. Use custom Docker image or conda/pip
- **Need > 5 days walltime**: Email hpc-help@wm.edu
- **Home quota exceeded (50GB)**: Use `/sciclone/scr10` or `/scr20`
