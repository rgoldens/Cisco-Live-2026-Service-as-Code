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

---

## Version 0.2

**Date:** 2026-03-19

### Summary
Expanded topology to 10 nodes (added linux-client3 and linux-client4), installed Ansible
and Terraform on the lab server, built a full Ansible inventory for all nodes with
working connectivity, set NX-OS hostnames via Ansible, and integrated hostname
configuration into the post-deploy pipeline.

---

### 0.2.1 — Automation Tools Installed

Ansible and Terraform installed on `198.18.134.90` (the ContainerLab server).
Decision: consolidate all automation tools on the single clab server so lab participants
connect to one IP via VSCode.

| Tool | Version |
|---|---|
| Ansible | `core 2.20.3` |
| Terraform | `v1.14.7` |
| ansible-pylibssh | `1.4.0` |

`ansible-pylibssh` installed to replace paramiko as the default SSH transport. CSR1000v
nodes require paramiko (legacy KEX) — see 0.2.3 for details.

---

### 0.2.2 — Topology Expanded to 10 Nodes

Two new Linux client nodes added:

| Node | IP | Connected to |
|---|---|---|
| `linux-client3` | `172.20.20.42` | `n9k-ce01:eth4` |
| `linux-client4` | `172.20.20.43` | `n9k-ce02:eth4` |

`LTRATO-1001.clab.yml` updated with new nodes and links.
`post-deploy.sh` updated to include `linux-client3` and `linux-client4` in the admin key
copy loop.
`/etc/ssh/ssh_config.d/clab-LTRATO-1001-passwords.conf` updated to add new Linux clients
to the `Host` line.

Lab destroyed (preserving `xr-storage`) and redeployed with the 10-node topology.
Passwordless SSH verified for all 4 Linux clients (root and admin).

**Full 10-node topology:**

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
| `linux-client3` | `linux` | `ghcr.io/hellt/network-multitool` | `172.20.20.42` |
| `linux-client4` | `linux` | `ghcr.io/hellt/network-multitool` | `172.20.20.43` |

---

### 0.2.3 — Ansible Inventory and Connectivity

`inventory.yml` written for all 10 nodes at `/home/cisco/inventory.yml`.
`ansible.cfg` written at `/home/cisco/ansible.cfg`.

**Key Ansible decisions per node type:**

| Group | Transport | Auth | Notes |
|---|---|---|---|
| `xrd` | `network_cli` / libssh | RSA pubkey (`id_rsa`) | Works with pylibssh |
| `csr` | `network_cli` / **paramiko** | **Password** | CSR 16.12 rejects rsa-sha2 signatures with hard disconnect; use password via paramiko with `look_for_keys=False` (set in `ansible.cfg [paramiko_connection]`) |
| `nxos` | `network_cli` / libssh | ed25519 pubkey | Legacy KEX args in `ansible_ssh_extra_args` |
| `linux` | `ssh` | ed25519 pubkey (`id_ed25519`) | No Python — use `raw` module |

All 10 nodes verified reachable via `ansible all -m raw -a 'echo ok'`.

---

### 0.2.4 — NX-OS Hostnames via Ansible

ContainerLab's `startup-config:` does NOT work for vrnetlab-based nodes (NX-OS, CSR).
The config file is placed in the lab directory but never loaded by the VM.

NX-OS hostnames set via Ansible using `cisco.nxos.nxos_config`.
Playbook `set_hostnames.yml` written and integrated into `post-deploy.sh` so hostnames
are applied automatically after every deploy.

`post-deploy.sh` now runs 3 steps:
1. Re-create `authorized_keys` as `root:root 600`
2. Copy `authorized_keys` into all 4 Linux container admin home dirs via `docker exec`
3. Wait for NX-OS health, then run `set_hostnames.yml` via Ansible

---

### Addressing Plan (agreed, not yet configured)

| Block | Purpose |
|---|---|
| `10.0.0.0/24` | Loopbacks |
| `10.1.0.0/24` | SP Core P2P links |
| `10.2.0.0/24` | PE-CE links |
| `10.3.0.0/24` | DC inter-CE link |
| `192.168.1.0/24` | Client west (client1, client3) |
| `192.168.2.0/24` | Client east (client2, client4) |

---

### 0.2.5 — Terraform Demo Topology (Docker Compose)

A separate Terraform demonstration environment deployed alongside the main ContainerLab topology.
Uses plain Docker containers (not ContainerLab) to avoid management network conflicts.

**Network:** `terraform-net` Docker bridge — `172.20.21.0/24`

| Container | Image | IP | Role |
|---|---|---|---|
| `csr-terraform` | `vrnetlab/vr-csr:16.12.05` | `172.20.21.10` | IOS XE router — Terraform target |
| `linux-terraform1` | `ghcr.io/hellt/network-multitool` | `172.20.21.20` | Linux client |
| `linux-terraform2` | `ghcr.io/hellt/network-multitool` | `172.20.21.21` | Linux client |

Deployed at `~/terraform-lab/` via `docker compose up -d`.

**RESTCONF enabled** on `csr-terraform` via Ansible playbook (`enable-restconf.yml`) using
paramiko transport (same CSR 16.12 legacy KEX workaround as main topology CSRs).
Verified working: `curl -k -u admin:admin https://172.20.21.10/restconf/data/...`

**Terraform provider:** `CiscoDevNet/iosxe` v0.16.0 installed via filesystem mirror
(`~/.terraform.d/plugins/`) — server has no internet access to registry.terraform.io.
`~/.terraformrc` configured with `filesystem_mirror` path.

Key discovery: `CiscoDevNet/iosxe` v0.16.0 defaults to NETCONF. Must set `protocol = "restconf"`
in the provider block to force RESTCONF/HTTPS transport.

**`terraform apply` succeeded** — applied 2 resources in ~2 seconds via RESTCONF:
- `iosxe_system.csr_terraform` — hostname set to `csr-terraform`
- `iosxe_interface_loopback.lo0` — Loopback0 `10.99.99.1/32` with description "Managed by Terraform"

Both changes verified on the CSR via RESTCONF curl queries.

---

### Files — Version 0.2

| File | Location | Description |
|---|---|---|
| `LTRATO-1001.clab.yml` | server: `~/` | 10-node topology (added client3, client4) |
| `post-deploy.sh` | server: `~/` | Now also runs set_hostnames.yml (3 steps) |
| `inventory.yml` | server: `~/` | Ansible inventory for all 10 nodes |
| `ansible.cfg` | server: `~/` | `host_key_checking=False`, `look_for_keys=False` |
| `set_hostnames.yml` | server: `~/` | Ansible playbook: set NX-OS hostnames |
| `LTRATO-1001-topology.drawio` | local untracked | Layered topology diagram with 10 nodes and full addressing plan |
| `terraform-lab/docker-compose.yml` | server: `~/terraform-lab/` | Terraform demo 3-container topology |
| `terraform-lab/enable-restconf.yml` | server: `~/terraform-lab/` | Ansible: enable RESTCONF on csr-terraform |
| `terraform-lab/terraform-inventory.yml` | server: `~/terraform-lab/` | Ansible inventory for csr-terraform |
| `terraform-lab/ansible.cfg` | server: `~/terraform-lab/` | paramiko, look_for_keys=False |
| `terraform-lab/terraform/main.tf` | server: `~/terraform-lab/terraform/` | Terraform config — hostname + Loopback0 via RESTCONF |
| `terraform-lab-docker-compose.yml` | local untracked | Local copy of docker-compose |
| `terraform-main.tf` | local untracked | Local copy of main.tf |
| `terraform-enable-restconf.yml` | local untracked | Local copy of enable-restconf playbook |
| `terraform-inventory.yml` | local untracked | Local copy of terraform inventory |
| `terraform-ansible.cfg` | local untracked | Local copy of terraform ansible.cfg |
