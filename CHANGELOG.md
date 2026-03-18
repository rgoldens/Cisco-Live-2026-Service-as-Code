# dCLOUD Build Version Control — LTRATO-1001

**Lab:** Cisco Live 2026 — LTRATO-1001 MPLS/VPN Topology
**Server:** `198.18.134.90` (user: `cisco`)
**ContainerLab version:** 0.74.1

---

## Version 0.1

**Date:** 2026-03-17

### Summary
Initial build of the LTRATO-1001 ContainerLab topology on the dCLOUD server.
All images deployed and validated, base topology wired, passwordless SSH working
for all nodes, and auto-start on server boot configured via systemd.

---

### 0.1.1 — Images Uploaded and Validated

All NOS images loaded onto the ContainerLab server and confirmed stable.

| Image | Tag | NOS |
|---|---|---|
| `ios-xr/xrd-control-plane` | `25.4.1` | Cisco IOS XR (XRd) |
| `vrnetlab/vr-csr` | `16.12.05` | Cisco IOS XE (CSR1000v) |
| `vrnetlab/vr-n9kv` | `10.5.4.M` | Cisco NX-OS (Nexus 9300v) |
| `ghcr.io/hellt/network-multitool` | `latest` | Alpine Linux |

**CSR1000v** — `vrnetlab/launch.py` patched to inject RSA public key in 6×72-character
chunks and add `aaa authorization exec default local`. Image rebuilt.

**NX-OS** — `vrnetlab/launch.py` patched to inject ed25519 public key. Image rebuilt.

Each NOS was individually deployed as a 2-node test lab and confirmed stable before
the full topology was assembled.

---

### 0.1.2 — Base Topology

Topology file: `LTRATO-1001.clab.yml`

**8-node topology:**

| Node | Kind | Image | Management IP |
|---|---|---|---|
| `xrd01` | `cisco_xrd` | `ios-xr/xrd-control-plane:25.4.1` | `172.20.20.10` |
| `xrd02` | `cisco_xrd` | `ios-xr/xrd-control-plane:25.4.1` | `172.20.20.11` |
| `csr-pe01` | `cisco_csr1000v` | `vrnetlab/vr-csr:16.12.05` | `172.20.20.20` |
| `csr-pe02` | `cisco_csr1000v` | `vrnetlab/vr-csr:16.12.05` | `172.20.20.21` |
| `n9k-ce01` | `cisco_n9kv` | `vrnetlab/vr-n9kv:10.5.4.M` | `172.20.20.30` |
| `n9k-ce02` | `cisco_n9kv` | `vrnetlab/vr-n9kv:10.5.4.M` | `172.20.20.31` |
| `linux-client1` | `linux` | `ghcr.io/hellt/network-multitool` | `172.20.20.40` |
| `linux-client2` | `linux` | `ghcr.io/hellt/network-multitool` | `172.20.20.41` |

**Links:**

| Link | Endpoints |
|---|---|
| P-to-P core | `xrd01:Gi0-0-0-0` ↔ `xrd02:Gi0-0-0-0` |
| xrd01 → PE01 | `xrd01:Gi0-0-0-1` ↔ `csr-pe01:eth1` |
| xrd02 → PE02 | `xrd02:Gi0-0-0-1` ↔ `csr-pe02:eth1` |
| Inter-PE | `csr-pe01:eth2` ↔ `csr-pe02:eth2` |
| PE01 → CE01 | `csr-pe01:eth3` ↔ `n9k-ce01:eth1` |
| PE02 → CE02 | `csr-pe02:eth3` ↔ `n9k-ce02:eth1` |
| DC inter-CE | `n9k-ce01:eth2` ↔ `n9k-ce02:eth2` |
| CE01 → Client1 | `n9k-ce01:eth3` ↔ `linux-client1:eth1` |
| CE02 → Client2 | `n9k-ce02:eth3` ↔ `linux-client2:eth1` |

All management IPs pinned via `mgmt-ipv4:` in the topology YAML to remain stable
across destroy/deploy cycles.

---

### 0.1.3 — Passwordless SSH

Two SSH keys provisioned on the server (`/home/cisco/.ssh/`):

| Key | Used for |
|---|---|
| `id_rsa` | XRd nodes, CSR1000v nodes |
| `id_ed25519` | NX-OS nodes, Linux nodes |

**XRd** — RSA public key baked into `xrd01-startup.cfg` and `xrd02-startup.cfg`
via `ssh server username clab keystring ssh-rsa ...`. ContainerLab loads this into
`first-boot.cfg` on every deploy. No expect script required.

**CSR1000v** — RSA public key injected by patched `vrnetlab/launch.py` in 72-character
chunks. `aaa authorization exec default local` added to allow exec shell on pubkey login.

**NX-OS** — ed25519 public key injected by patched `vrnetlab/launch.py`.

**Linux nodes** — `authorized_keys` file bind-mounted into `/root/.ssh/` (read-only).
File must be owned `root:root` with permissions `600`. `openssh` installed at runtime
via Alpine 3.12 APK mirror. SSH daemon started via `exec:` in topology YAML.
`admin` user created; `authorized_keys` copied into `/home/admin/.ssh/` by
`post-deploy.sh` via `docker exec` after deploy (timing issue prevented doing this
during `exec:` steps).

SSH client config written to `/etc/ssh/ssh_config.d/clab-LTRATO-1001-passwords.conf`
using absolute key paths (required because systemd runs as root where `~` = `/root/`).

**Verified passwordless SSH for all nodes and users:**

| Node | User | Key type | Status |
|---|---|---|---|
| xrd01 | `clab` | RSA | ✅ |
| xrd02 | `clab` | RSA | ✅ |
| csr-pe01 | `admin` | RSA | ✅ |
| csr-pe02 | `admin` | RSA | ✅ |
| n9k-ce01 | `admin` | ed25519 | ✅ |
| n9k-ce02 | `admin` | ed25519 | ✅ |
| linux-client1 | `root` | ed25519 | ✅ |
| linux-client1 | `admin` | ed25519 | ✅ |
| linux-client2 | `root` | ed25519 | ✅ |
| linux-client2 | `admin` | ed25519 | ✅ |

---

### 0.1.4 — Auto-Start on Server Boot

Two systemd services installed and enabled on the server:

**`containerlab-labs.service`**
- Runs as `root`
- `ExecStartPre`: destroys any stale containers left over from previous shutdown
  (`containerlab destroy || true`) to prevent "containers already exist" errors on reboot
- `ExecStartPre`: pre-creates `authorized_keys` as `root:root 600` before deploy
- `ExecStart`: runs `containerlab deploy -t /home/cisco/LTRATO-1001.clab.yml`
  (without `--reconfigure` to preserve XRd `xr-storage` and host keys)
- `ExecStop`: runs `containerlab destroy`
- `TimeoutStartSec=600`

**`containerlab-post-deploy.service`**
- Runs after `containerlab-labs.service`
- Executes `/home/cisco/post-deploy.sh`
- Re-creates `authorized_keys` as `root:root 600` (ContainerLab resets ownership on deploy)
- Copies `authorized_keys` into `/home/admin/.ssh/` inside both Linux containers
  via `docker exec`
- `TimeoutStartSec=1800`

**Key discovery:** `containerlab deploy --reconfigure` destroys the entire lab directory
including XRd `xr-storage`. Plain `destroy` preserves it. The safe redeploy pattern is
`destroy` → write configs → `deploy`.

---

### Files — Version 0.1

| File | Location | Description |
|---|---|---|
| `LTRATO-1001.clab.yml` | server: `~/` | Main topology definition |
| `xrd01-startup.cfg` | server: `~/` | XRd01 base config + RSA pubkey |
| `xrd02-startup.cfg` | server: `~/` | XRd02 base config + RSA pubkey |
| `post-deploy.sh` | server: `~/` | Fixes authorized_keys + admin key copy |
| `containerlab-labs.service` | server: `/etc/systemd/system/` | Deploy on boot |
| `containerlab-post-deploy.service` | server: `/etc/systemd/system/` | Post-deploy key fix |
| `/etc/ssh/ssh_config.d/clab-LTRATO-1001-passwords.conf` | server | Per-node SSH client config |
| `/home/cisco/.ssh/id_rsa` + `.pub` | server | RSA key for XRd/CSR |
| `/home/cisco/.ssh/id_ed25519` + `.pub` | server | ed25519 key for NX-OS/Linux |
