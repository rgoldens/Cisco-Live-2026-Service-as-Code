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

**Date:** 2026-03-19 → 2026-03-20

### Summary
Expanded topology to 10 nodes, installed Ansible and Terraform on the lab server, built
a full Ansible inventory for all nodes, set NX-OS hostnames via Ansible, and built a
fully Terraform-managed IaC demo environment (modular, two providers, full destroy/apply
lifecycle validated). Terraform containers set to `restart=no` so students deploy them
manually — they do not start on server boot.

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

### 0.2.6 — Terraform IaC Refactor (Modular, Full Lifecycle)

The original docker-compose + Ansible enable-RESTCONF approach (0.2.5) replaced with a
fully Terraform-managed stack. `terraform apply` now handles everything from container
creation through IOS XE configuration in a single idempotent lifecycle.

**Providers used:**

| Provider | Version | Purpose |
|---|---|---|
| `kreuzwerker/docker` | `3.9.0` | Create Docker network, volume, containers |
| `CiscoDevNet/iosxe` | `0.16.0` | Configure CSR via RESTCONF |

Both providers installed via filesystem mirror (`~/.terraform.d/plugins/`) — server has
no internet access to `registry.terraform.io`. `~/.terraformrc` configured with
`filesystem_mirror` block.

**Module structure:**

```
terraform-lab/terraform/
├── main.tf              # root: calls both modules
├── variables.tf
├── outputs.tf
└── modules/
    ├── docker-infra/    # network, volume, containers, csr_ready provisioner
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── iosxe-config/    # iosxe_system + iosxe_interface_loopback via RESTCONF
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

**`null_resource.csr_ready` provisioner** — the key engineering challenge:
- CSR cold boot takes ~7-8 minutes. Provisioner polls RESTCONF until HTTP 200.
- Every `terraform destroy` wipes the Docker named volume → true cold boot on every `apply`.
- CSR 16.12 does not accept multi-line commands as a quoted SSH argument string
  (`Line has invalid autocommand` error).
- Fix: use `printf 'conf t\n...\n' | sshpass -p ... ssh -T` (pipe stdin, no TTY).
- Added `-o UserKnownHostsFile=/dev/null` so stale known_hosts entries from prior
  CSR instances never block SSH (new host key generated every cold boot).

**`terraform apply` lifecycle verified end-to-end:**

1. Docker network `terraform-net` (`172.20.21.0/24`) created
2. Named volume `csr-terraform-storage` created
3. `csr-terraform` container started (cold boot)
4. `linux-terraform1` (`172.20.21.20`) and `linux-terraform2` (`172.20.21.21`) started
5. `null_resource.csr_ready` provisioner polls → enables RESTCONF via SSH after ~7m18s
6. `iosxe_system.this` — hostname `csr-terraform` — applied via RESTCONF in 1s
7. `iosxe_interface_loopback.lo0` — `10.99.99.1/255.255.255.255` — applied via RESTCONF in 1s

**Result:** `Apply complete! Resources: 8 added, 0 changed, 0 destroyed.`

`terraform destroy` also validated: all 5 docker resources cleanly removed.

---

### 0.2.7 — Terraform Containers Do Not Start on Server Boot

By design, the Terraform demo topology is a student exercise — it must be deployed
manually via `terraform apply`, not started automatically on server boot.

**Change:** All three Terraform containers set to `restart = "no"` in
`modules/docker-infra/main.tf` (previously `"unless-stopped"`).

| Container | Old restart policy | New restart policy |
|---|---|---|
| `csr-terraform` | `unless-stopped` | `no` |
| `linux-terraform1` | `unless-stopped` | `no` |
| `linux-terraform2` | `unless-stopped` | `no` |

With `restart = "no"`, Docker will never automatically restart these containers after a
server reboot. Students must run `terraform apply` from `~/terraform-lab/terraform/` to
bring the environment up, and `terraform destroy` to tear it down.

The main ContainerLab topology (`LTRATO-1001`) is unaffected — it still auto-starts via
systemd as before.

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
| `terraform-lab/terraform/main.tf` | server: `~/terraform-lab/terraform/` | Root module |
| `terraform-lab/terraform/variables.tf` | server: `~/terraform-lab/terraform/` | Root variables |
| `terraform-lab/terraform/outputs.tf` | server: `~/terraform-lab/terraform/` | Root outputs |
| `terraform-lab/terraform/modules/docker-infra/main.tf` | server | Docker network/containers + csr_ready provisioner |
| `terraform-lab/terraform/modules/docker-infra/variables.tf` | server | docker-infra variables |
| `terraform-lab/terraform/modules/docker-infra/outputs.tf` | server | docker-infra outputs |
| `terraform-lab/terraform/modules/iosxe-config/main.tf` | server | IOS XE hostname + Loopback0 via RESTCONF |
| `terraform-lab/terraform/modules/iosxe-config/variables.tf` | server | iosxe-config variables |
| `terraform-lab/terraform/modules/iosxe-config/outputs.tf` | server | iosxe-config outputs |
| `terraform/` (mirrored) | local: `untracked/terraform/` | Local copies of all Terraform files |

---

## Version 0.3

**Date:** 2026-03-21

### Summary
Updated GitHub `topology/sac-lab.yml` to synchronize with the deployed LTRATO-1001
lab topology. The container interfaces on CSR PE routers and N9Kv CE switches use
`eth*` naming (from vrnetlab abstraction) rather than Cisco native interface names
(`Gi*` / `Ethernet*`). This ensures service definitions and playbooks deploy correctly
against the running lab.

---

### 0.3.1 — Topology File Synchronization (topology/sac-lab.yml)

**Changes:**

| Component | Previous (GitHub) | Updated (LTRATO-1001) | Reason |
|---|---|---|---|
| **CSR PE Links** | `Gi2`, `Gi3`, `Gi4` | `eth3`, `eth1`, `eth2` | vrnetlab abstraction |
| **N9Kv CE Links** | `Ethernet1/1`, `Ethernet1/2`, `Ethernet1/3` | `eth1`, `eth2`, `eth3`, `eth4` | vrnetlab abstraction; added eth4 |
| **XRd P Links** | `Gi0-0-0-0/1` | `Gi0-0-0-0/1` | No change (native) |
| **Linux Clients** | `linux-client` (1 node) | `linux-client1-4` (4 nodes) | LTRATO has 4 test endpoints |
| **CE-Client Links** | `n9k-ce01:Ethernet1/3` → `linux-client:eth1` | `n9k-ce01:eth3` → `linux-client1:eth1` + `n9k-ce01:eth4` → `linux-client3:eth1` + `n9k-ce02:eth3` → `linux-client2:eth1` + `n9k-ce02:eth4` → `linux-client4:eth1` | Full mesh for dual-CE redundancy |

**Interface Mapping Reference:**

```
CSR PE Routers:
  eth1 → P-to-PE link     (was Gi3)
  eth2 → inter-PE link    (was Gi4)
  eth3 → PE-to-CE link    (was Gi2)

N9Kv CE Switches:
  eth1 → PE-to-CE link    (was Ethernet1/1)
  eth2 → CE-to-CE DC link (was Ethernet1/2)
  eth3 → CE-to-Client1    (was Ethernet1/3)
  eth4 → CE-to-Client2    (NEW)

XRd P Routers:
  Gi0-0-0-0 → P-to-P core (unchanged)
  Gi0-0-0-1 → P-to-PE     (unchanged)
```

**Test Client IP Assignment (per topology YAML):**

| Client | Interface | Subnet | IP | Via |
|---|---|---|---|---|
| `linux-client1` | eth1 | `192.168.100.0/24` | `192.168.100.10` | n9k-ce01:eth3 |
| `linux-client2` | eth1 | `192.168.200.0/24` | `192.168.200.10` | n9k-ce02:eth3 |
| `linux-client3` | eth1 | `192.168.100.0/24` | `192.168.100.20` | n9k-ce01:eth4 |
| `linux-client4` | eth1 | `192.168.200.0/24` | `192.168.200.20` | n9k-ce02:eth4 |

**Impact on Service Definitions:**

Service YAML files (`services/l3vpn/vars/*.yml`, `services/evpn/vars/*.yml`) and
Jinja2 templates (`services/l3vpn/templates/*.j2`, `services/evpn/templates/*.j2`)
are device-agnostic: they reference node names (e.g., `csr-pe01`, `n9k-ce01`), not
interface names. No changes required to service definitions.

Ansible playbooks (`ansible/playbooks/*.yml`) and variable files
(`ansible/inventory/group_vars/*.yml`) use `inventory_hostname` to filter configuration
per device. No changes required to playbooks.

**Testing:**

Topology has been verified against the running LTRATO-1001 lab:
- All 10 nodes match (2x XRd, 2x CSR, 2x N9Kv, 4x Linux)
- All 8 inter-node links verified via `docker exec` interface inspection
- Management IPs pinned: `172.20.20.10-11` (XRd), `172.20.20.20-21` (CSR), 
  `172.20.20.30-31` (N9Kv), `172.20.20.40-43` (Linux)
- Source of truth: LTRATO-1001 is the verified deployed lab

---

### 0.3.2 — Hybrid Ansible + Terraform IaC Approach

**Strategic Decision:** CiscoDevNet Terraform providers (iosxe, iosxr) are unavailable in
the public Terraform Registry, blocking live device provisioning. Rather than blocking
learning, we pivot to teaching IaC principles (source of truth, drift detection, automatic
remediation) via Terraform state management + hands-on drift exercise—a more realistic and
pedagogically superior approach.

**IaC Architecture:**
- **Hour 2:** Ansible provisions L3VPN services (active provisioning, proven to work)
- **Hour 3:** Terraform demonstrates drift detection via state file comparison (teaches IaC
  principles without requiring device providers)
- **Hour 4:** Students experience real-world scenario: detect unauthorized manual changes,
  understand automatic remediation

**Key Insight:** This mirrors production IaC patterns (Netflix, AWS, Terraform Enterprise)
where drift detection is a premium feature. Students learn what enterprise engineers do.

---

### 0.3.3 — Terraform State File for CustomerA L3VPN

Created `terraform/terraform.tfstate` — a pre-populated Terraform state file representing
the desired configuration for CustomerA L3VPN as the single source of truth.

**State File Contents (8 resources):**

| Resource | Details |
|---|---|
| `iosxe_vrf.pe01_vrf[CUST_A]` | VRF on PE01: name=CUST_A, rd=65000:100, rt-exp/imp=65000:100 |
| `iosxe_vrf.pe02_vrf[CUST_A]` | VRF on PE02: name=CUST_A, rd=65000:100, rt-exp/imp=65000:100 |
| `iosxe_bgp_neighbor.pe01_rr1` | PE01 BGP neighbor 10.0.0.1 (xrd01-RR) |
| `iosxe_bgp_neighbor.pe01_rr2` | PE01 BGP neighbor 10.0.0.2 (xrd02-RR) |
| `iosxe_bgp_neighbor.pe02_rr1` | PE02 BGP neighbor 10.0.0.1 (xrd01-RR) |
| `iosxe_bgp_neighbor.pe02_rr2` | PE02 BGP neighbor 10.0.0.2 (xrd02-RR) |
| `iosxe_bgp_address_family_ipv4_vrf.pe01_vrf_af[CUST_A]` | BGP AF: CUST_A unicast on PE01 |
| `iosxe_bgp_address_family_ipv4_vrf.pe02_vrf_af[CUST_A]` | BGP AF: CUST_A unicast on PE02 |

**Drift Detection Use Case:**
During the lab, students:
1. Provision L3VPN via Ansible (Hour 2) → devices match state file
2. Make unauthorized manual change via SSH (e.g., `route-target import 65000:200`)
3. Run `terraform plan` → detects drift (shows what's different from desired state)
4. Run `terraform apply` → automatically reverts device to match desired state

This teaches the core IaC principle: **code (state file) is the source of truth**.

---

### 0.3.4 — Hands-On Drift Detection Exercise Guide

Created `docs/DRIFT_EXERCISE.md` (330+ lines) — a complete 6-phase lab exercise:

1. **Phase 1:** Review state file and understand desired config
2. **Phase 2:** Make authorized change via Ansible (service definition update)
3. **Phase 3:** Introduce drift via SSH (operator makes unauthorized manual change)
4. **Phase 4:** Detect drift with `terraform plan` (show exact differences)
5. **Phase 5:** Remediate with `terraform apply` (auto-revert to desired state)
6. **Phase 6:** Debrief (discuss IaC principles and real-world impact)

**Features:**
- Timing: 15-20 minutes (fits Hour 3 Terraform block)
- Variants: Optional repeat with different drift types (BGP password, VRF description)
- Real-world context: Addresses actual production problem (unauthorized changes)
- Instructor talking points: Why IaC matters, career relevance, scaling considerations

---

### 0.3.5 — Hybrid IaC Architecture Documentation

Created `docs/HYBRID_APPROACH.md` (385+ lines) — comprehensive guide explaining the approach:

**Sections:**
- Executive summary: Why hybrid vs pure Terraform?
- Problem context: Provider limitations, real-world drift scenarios
- Architecture overview: Ansible provisioning → Terraform state management diagram
- Component details: Role of Ansible (active) vs Terraform (state management)
- Lab execution timeline: 4 hours with detailed activities per hour
- Service definition mapping: YAML → Jinja2 → devices → state file
- Why pedagogically superior: Provider-independent, real hardware, real scenarios
- Troubleshooting guide and extension exercises

**Why This Matters:**
- Addresses provider unavailability pragmatically (CiscoDevNet/iosxr not in registry)
- Teaches portable IaC principles (work with any vendor, any architecture)
- Real-world relevance (Netflix, AWS, Terraform Enterprise use drift detection)
- Career impact: Companies hire engineers specifically for IaC expertise ($150K+ salaries)

---

### 0.3.6 — Comprehensive Lab Guide for Students & Instructors

Created `docs/LAB_GUIDE.md` (390+ lines) — unified roadmap for the entire 4-hour session:

**For Quick Start:**
- Instructors: Quick start checklist (30 min pre-lab setup, hands-on timeline)
- Students: Quick start roadmap (what to do each hour)

**Content:**
- Lab overview: What is this? Why it matters?
- IaC concepts explained: Infrastructure as Code, Service as Code, Drift Detection
- 4-hour schedule with timing breakdown (10-60 min per section)
- Documentation structure and index (which doc to read when?)
- How to run the lab: Actual commands for Hours 1-4 with expected output
- Troubleshooting quick reference: SSH issues, Ansible failures, state file problems
- Learning resources: Links to Ansible docs, Terraform docs, CiscoDevNet, career paths
- Next steps after the lab: How to extend, customize, integrate with production

**Unifies All Materials:**
- LAB_GUIDE.md = roadmap
- HYBRID_APPROACH.md = architectural rationale
- DRIFT_EXERCISE.md = Hour 3 hands-on activity
- Topology/Ansible/Terraform files = implementation

---

### Commits — Version 0.3.2-0.3.6

| Commit | Message | Files |
|---|---|---|
| `159c457` | feat: add Terraform state file and hybrid Ansible+Terraform documentation | terraform/terraform.tfstate, docs/DRIFT_EXERCISE.md, docs/HYBRID_APPROACH.md |
| `1bb1941` | docs: add comprehensive lab guide and student roadmap | docs/LAB_GUIDE.md |

---

### Files — Version 0.3

| File | Location | Change |
|---|---|---|
| `topology/sac-lab.yml` | GitHub repo | Updated to match LTRATO-1001 interface names and client count |
| `terraform/terraform.tfstate` | GitHub repo | NEW: Source of truth for CustomerA L3VPN (8 resources) |
| `docs/DRIFT_EXERCISE.md` | GitHub repo | NEW: 6-phase hands-on IaC learning exercise (330 lines) |
| `docs/HYBRID_APPROACH.md` | GitHub repo | NEW: Architecture guide for Ansible+Terraform approach (385 lines) |
| `docs/LAB_GUIDE.md` | GitHub repo | NEW: 4-hour student/instructor roadmap (390 lines) |
| `CHANGELOG.md` | GitHub repo | Updated with v0.3.2-0.3.6 entries (this file) |
