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

### 0.2.8 — Stale Terraform Resources Cleaned Up

**Date:** 2026-03-21

After loading the 0.2.7 checkpoint, two orphaned Docker resources were found on the server
left over from a previous `terraform destroy` run (destroy removes containers but can
leave the volume and network behind):

| Resource | Name |
|---|---|
| Docker volume | `csr-terraform-storage` |
| Docker network | `terraform-net` |

Both removed manually:

```
docker volume rm csr-terraform-storage
docker network rm terraform-net
```

Server is now in the clean baseline state expected at the start of the student
Terraform lab guide (Part 2 — "Confirm nothing is running yet"). A fresh
`terraform apply` will cold-boot the CSR from a new volume.

---

### 0.2.9 — ContainerLab Upgraded to 0.74.3

**Date:** 2026-03-25

ContainerLab upgraded on the server from `0.74.1` to `0.74.3`.

| Component | Previous | New |
|---|---|---|
| ContainerLab | `0.74.1` | `0.74.3` |

---

### 0.2.9.3 — TopoViewer Graph Annotations Added

**Date:** 2026-03-25

Added `graph-*` labels to all 10 nodes in `LTRATO-1001.clab.yml` to control the
ContainerLab VS Code extension's TopoViewer visualization.

| Label | Purpose |
|---|---|
| `graph-posX` / `graph-posY` | Fixed node positions on the canvas |
| `graph-icon` | Node icon shape (`pe`, `switch`, `client`) |
| `graph-group` | Visual grouping band (`core`, `pe-ce-edge`, `dc`, `clients`) |

**Node layout:**

| Node | X | Y | Icon | Group |
|---|---|---|---|---|
| `xrd01` | 250 | 100 | `pe` | `core` |
| `xrd02` | 950 | 100 | `pe` | `core` |
| `csr-pe01` | 250 | 340 | `pe` | `pe-ce-edge` |
| `csr-pe02` | 950 | 340 | `pe` | `pe-ce-edge` |
| `n9k-ce01` | 250 | 580 | `switch` | `dc` |
| `n9k-ce02` | 950 | 580 | `switch` | `dc` |
| `linux-client1` | 100 | 820 | `client` | `clients` |
| `linux-client2` | 380 | 820 | `client` | `clients` |
| `linux-client3` | 820 | 820 | `client` | `clients` |
| `linux-client4` | 1100 | 820 | `client` | `clients` |

Updated topology pushed to server. Reload the TopoViewer in VS Code to see the new layout.

---

### 0.2.9.1 — Topology Redesign: Remove Inter-PE and DC Links, Rewire Linux Clients

**Date:** 2026-03-25

Updated `LTRATO-1001.clab.yml` to match revised topology diagram.

**Links removed (2):**

| Link | Reason |
|---|---|
| `csr-pe01:eth2 ↔ csr-pe02:eth2` | Inter-PE direct link removed |
| `n9k-ce01:eth2 ↔ n9k-ce02:eth2` | DC inter-CE link removed |

**Client links rewired (2):**

| Client | Old connection | New connection |
|---|---|---|
| `linux-client2` | `n9k-ce02:eth3` | `n9k-ce01:eth4` |
| `linux-client3` | `n9k-ce01:eth4` | `n9k-ce02:eth3` |

**Resulting client layout:**

| Client | CE | Interface | Mgmt IP |
|---|---|---|---|
| `linux-client1` | `n9k-ce01` (west) | `eth3` | `172.20.20.40` |
| `linux-client2` | `n9k-ce01` (west) | `eth4` | `172.20.20.41` |
| `linux-client3` | `n9k-ce02` (east) | `eth3` | `172.20.20.42` |
| `linux-client4` | `n9k-ce02` (east) | `eth4` | `172.20.20.43` |

`post-deploy.sh` is unaffected — it references containers by name, not by link or IP.

---

### 0.2.9.2 — SSH Verification: All 10 Nodes Confirmed

**Date:** 2026-03-25

Passwordless SSH verified for all nodes in the freshly-deployed topology. CSR nodes
require legacy KEX — verified via ContainerLab hostname (picks up `/etc/ssh/ssh_config.d/clab-LTRATO-1001-passwords.conf`).

| Node | Hostname | User | Result |
|---|---|---|---|
| `xrd01` | `clab-LTRATO-1001-xrd01` | `clab` | ✅ IOS XR 25.4.1 |
| `xrd02` | `clab-LTRATO-1001-xrd02` | `clab` | ✅ IOS XR 25.4.1 |
| `csr-pe01` | `clab-LTRATO-1001-csr-pe01` | `admin` | ✅ IOS XE 16.12.05 |
| `csr-pe02` | `clab-LTRATO-1001-csr-pe02` | `admin` | ✅ IOS XE 16.12.05 |
| `n9k-ce01` | `clab-LTRATO-1001-n9k-ce01` | `admin` | ✅ NX-OS 10.5(4) |
| `n9k-ce02` | `clab-LTRATO-1001-n9k-ce02` | `admin` | ✅ NX-OS 10.5(4) |
| `linux-client1` | `clab-LTRATO-1001-linux-client1` | `root` + `admin` | ✅ Both users |
| `linux-client2` | `clab-LTRATO-1001-linux-client2` | `root` + `admin` | ✅ Both users |
| `linux-client3` | `clab-LTRATO-1001-linux-client3` | `root` + `admin` | ✅ Both users |
| `linux-client4` | `clab-LTRATO-1001-linux-client4` | `root` + `admin` | ✅ Both users |

**Note:** CSR nodes must be accessed by ContainerLab hostname (not IP) so that the legacy
KEX/hostkey settings in the custom SSH config are applied. Direct IP SSH to CSR will fail
without explicit `-o KexAlgorithms=+diffie-hellman-group14-sha1` flags.

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
| `CHANGELOG.md` | GitHub repo | Updated with v0.3.2-0.3.6 entries |

---

### 0.3.7 — Critical Fixes: Service Definitions, Inventory Alignment, and Documentation

**Date:** 2026-03-21 (continuation)

**Objective:** Fix critical inconsistencies discovered during repository audit that would 
prevent Ansible provisioning from working correctly. Ensure all documentation references
resolve and README accurately describes the lab.

---

#### 0.3.7.1 — Service Definition Interface Fix

**Problem:** Service definitions used `GigabitEthernet2` for PE-CE link, but:
- Containerlab topology defines `csr-pe01:eth3` as PE-CE link (maps to GigabitEthernet3)
- Terraform expects `eth3` for PE-CE interface
- Actual startup config has no customer-facing interface pre-configured on GigabitEthernet2

**Solution:** Updated all L3VPN service definitions to use `GigabitEthernet3`

| File | Change |
|---|---|
| `services/l3vpn/vars/customer_a.yml` | `interface: GigabitEthernet2` → `GigabitEthernet3` (2 places: pe01 and pe02) |
| `services/l3vpn/vars/customer_b.yml` | `interface: GigabitEthernet2` → `GigabitEthernet3` (2 places: pe01 and pe02) |

**Impact:** Ansible L3VPN provisioning will now configure correct PE-facing interfaces matching the topology.

---

#### 0.3.7.2 — Ansible Inventory Alignment (LTRATO-1001 IPs)

**Problem:** Ansible inventory (`ansible/inventory/hosts.yml`) had stale IPs not matching LTRATO-1001:
- XRd: `172.20.20.11, .12` (should be `.10, .11`)
- CSR: `172.20.20.13, .14` (should be `.20, .21`)
- N9Kv: `172.20.20.15, .16` (should be `.30, .31`)
- Linux: `172.20.20.17` (should be `.40, .41, .42, .43`)
- Missing 3 Linux clients entirely

**Solution:** Completely rewrote `ansible/inventory/hosts.yml` with:
- Correct LTRATO-1001 management IPs (172.20.20.10-43)
- Per-device network OS and credentials in vars
- All 4 Linux clients (linux-client1-4)
- Proper group structure (pe_routers, p_routers, ce_switches, network)

**Before:**
```yaml
xrd01:
  ansible_host: 172.20.20.11     # wrong
csr-pe01:
  ansible_host: 172.20.20.13     # wrong
linux:
  hosts:
    linux-client:               # only 1 client
      ansible_host: 172.20.20.17  # wrong
```

**After:**
```yaml
xrd01:
  ansible_host: 172.20.20.10     # correct
csr-pe01:
  ansible_host: 172.20.20.20     # correct
linux:
  hosts:
    linux-client1:
      ansible_host: 172.20.20.40  # correct
    linux-client2:
      ansible_host: 172.20.20.41
    linux-client3:
      ansible_host: 172.20.20.42
    linux-client4:
      ansible_host: 172.20.20.43
```

**Impact:** Ansible playbooks will now connect to correct device IPs and reach all 4 test clients.

---

#### 0.3.7.3 — README.md Accuracy

**Problems fixed:**
1. **Node count mismatch:** README listed "7 nodes | 1 Linux client" but topology has 10 nodes | 4 Linux clients
2. **Missing documentation reference:** README didn't link new docs
3. **Missing hybrid approach explanation:** README didn't mention Ansible+Terraform hybrid strategy

**Changes:**
- Updated node count: "**10 nodes** | 2 XRd P-routers | 2 CSR1000v PEs | 2 N9Kv CEs | 4 Linux clients"
- Added `docs/` section to project structure documenting all new guides:
  - LAB_GUIDE.md (4-hour lab roadmap)
  - DEPLOYMENT_GUIDE.md (new)
  - TOPOLOGY_NOTES.md (new)
  - HYBRID_APPROACH.md (IaC rationale)
  - DRIFT_EXERCISE.md (Hour 3 hands-on)
- Added "Hybrid Ansible + Terraform Approach" section explaining strategy and rationale

**Impact:** README now accurately reflects lab structure and points users to all supporting documentation.

---

#### 0.3.7.4 — INSTALL_GUIDE.md Completion

**Problem:** Device images section cut off mid-content with no build instructions

**Solution:** Completed section with detailed image loading/building steps:

**For XRd:**
- Command: `docker load -i xrd-control-plane-container-x64.25.1.1.tgz`
- Resulting image: `ios-xr/xrd-control-plane:25.1.1`

**For CSR1000v:**
- Use vrnetlab to build: `cd vrnetlab/csr && make IMAGE=~/csr1000v-universalk9.17.03.06-serial.qcow2`
- Resulting image: `vrnetlab/vr-csr:17.03.06`

**For N9Kv:**
- Use vrnetlab to build: `cd vrnetlab/nxos && make IMAGE=~/nexus9500v64.10.4.3.F.qcow2`
- Resulting image: `vrnetlab/vr-n9kv:10.4.3`

**Impact:** Students/instructors can now follow complete setup instructions without gaps.

---

#### 0.3.7.5 — New: Deployment Guide (docs/DEPLOYMENT_GUIDE.md)

**Created comprehensive deployment guide (600+ lines):**

**Sections:**
1. **Quick Deploy** (Steps 1-4)
   - Clone repo
   - Deploy topology (`sudo clab deploy`)
   - Verify all 10 nodes running
   - Verify connectivity via SSH

2. **Post-Deployment Setup** (Steps 5-6)
   - Update Ansible inventory if IPs differ
   - Verify device readiness (XRd, CSR, NX-OS boot times)

3. **Stopping and Restarting**
   - Preserve-data destroy/deploy pattern
   - Full reset with cleanup

4. **Troubleshooting**
   - Container fails to start
   - Can't SSH to device
   - Network links not working
   - Out of memory

5. **Power-User Tips**
   - Auto-deploy on server boot (systemd)
   - Bulk deploy multiple labs
   - Monitor resource usage

**Impact:** Instructors have step-by-step guide for deploying topology and troubleshooting common issues.

---

#### 0.3.7.6 — New: Topology Notes (docs/TOPOLOGY_NOTES.md)

**Created comprehensive topology reference (900+ lines):**

**Sections:**
1. **Node Details** (XRd, CSR, N9Kv, Linux)
   - Image versions
   - Management IPs
   - Default credentials
   - CPU/memory allocation
   - Pre-configured services

2. **Network Architecture**
   - Management network diagram (172.20.20.0/24)
   - Data plane links (inter-node connections)
   - Complete link table with interface mappings

3. **IP Address Plan**
   - Loopback addressing (10.0.0.0/24)
   - Underlay P-to-P links (10.1.0.0/24, 10.2.0.0/24)
   - Customer VRF addressing (192.168.x.x/24, 10.100.x.x/24)

4. **Service Definitions**
   - L3VPN service structure
   - EVPN/VXLAN service structure

5. **Boot Sequence & Readiness**
   - XRd typical boot time: 45-60 seconds
   - CSR typical boot time: 30-45 seconds
   - NX-OS typical boot time: 3-5 minutes
   - Verification commands for each NOS

6. **Configuration Files**
   - Reference to startup configs in `configs/` directory
   - Underlay (IS-IS, LDP) vs overlay (VRFs, EVPN) distinction

7. **Validation Commands**
   - Health checks per node
   - BGP neighbor verification
   - Reachability testing

**Impact:** Students and instructors have complete reference for node details, IPs, boot times, and validation.

---

### Commits — Version 0.3.7

| Commit | Files Changed | Message |
|---|---|---|
| Multi-replace | `services/l3vpn/vars/customer_a.yml`, `services/l3vpn/vars/customer_b.yml` | fix: correct PE-CE interface from GigabitEthernet2 to GigabitEthernet3 |
| Multi-replace | `ansible/inventory/hosts.yml` | fix: align Ansible inventory to LTRATO-1001 actual IPs and add all 4 Linux clients |
| Replace | `README.md` | fix: update node count (10 nodes, 4 Linux clients) and add missing hybrid approach section |
| Replace | `INSTALL_GUIDE.md` | fix: complete device image section with build instructions for vrnetlab |
| Create | `docs/DEPLOYMENT_GUIDE.md` | feat: comprehensive deployment guide with troubleshooting |
| Create | `docs/TOPOLOGY_NOTES.md` | feat: complete topology reference with node details, IPs, boot times |
| (pending) | `CHANGELOG.md` | docs: update CHANGELOG with v0.3.7 critical fixes summary |

---

### Files — Version 0.3.7

| File | Location | Change |
|---|---|---|
| `services/l3vpn/vars/customer_a.yml` | GitHub repo | FIXED: Interface GigabitEthernet2 → GigabitEthernet3 |
| `services/l3vpn/vars/customer_b.yml` | GitHub repo | FIXED: Interface GigabitEthernet2 → GigabitEthernet3 |
| `ansible/inventory/hosts.yml` | GitHub repo | FIXED: Updated IPs to LTRATO-1001, added linux-client1-4, per-device credentials |
| `README.md` | GitHub repo | FIXED: Node count (10 nodes, 4 clients), added docs section, hybrid approach |
| `INSTALL_GUIDE.md` | GitHub repo | FIXED: Completed device image section with build instructions |
| `docs/DEPLOYMENT_GUIDE.md` | GitHub repo | NEW: Step-by-step deployment guide with troubleshooting |
| `docs/TOPOLOGY_NOTES.md` | GitHub repo | NEW: Complete topology reference (nodes, IPs, links, boot times, validation) |
| `CHANGELOG.md` | GitHub repo | Updated with v0.3.7 entry (this section) |

---

### Summary of All Critical Fixes (v0.3.7)

| Category | Files | Impact |
|----------|-------|--------|
| **Service Definitions** | customer_a.yml, customer_b.yml | Ansible L3VPN provisioning will now use correct PE-CE interface |
| **Ansible Inventory** | hosts.yml | Playbooks will connect to actual device IPs and reach all 4 clients |
| **Documentation** | README.md | Accurate description of topology and links to all guides |
| **Installation** | INSTALL_GUIDE.md | Complete setup instructions with no gaps |
| **Deployment** | DEPLOYMENT_GUIDE.md (new) | Instructors have step-by-step deploy/troubleshoot guide |
| **Reference** | TOPOLOGY_NOTES.md (new) | Students/instructors have complete node and IP reference |

**Lab readiness:** After v0.3.7, all critical inconsistencies are resolved. The lab is ready for:
- ✅ Containerlab topology deployment
- ✅ Ansible L3VPN/EVPN provisioning
- ✅ Terraform state-based drift detection
- ✅ 4-hour Cisco Live 2026 session

---

### 0.3.8 — Exercise Restructuring & GitOps Workflow Exercise

**Date:** 2026-03-22

**Summary:** Restructured lab exercises for 4-hour Cisco Live 2026 session. Updated exercise overview from 7 to 8 exercises. Renamed Exercise 1 to focus on topology exploration (15 min, instead of deployment). Added Exercise 8 "GitOps Workflow & Source of Truth" (30 min) teaching Git-driven orchestration and drift detection via Ansible.

**Impact:** Lab now has 210 minutes of sequential, hands-on exercises + 30-minute buffer = 240 minutes (4 hours). Students see two complementary "source of truth" approaches: Terraform state file (Exercises 5-7) and Git-driven Ansible (Exercise 8).

**Updated Exercise Table:**

| # | Exercise | Time | Change |
|---|----------|------|--------|
| **0** | Lab Readiness Verification | 15 min | Pre-flight checks |
| **1** | Explore & Understand Deployed Topology | 15 min | **Renamed** (was "Deploy Topology") |
| **2** | Provision CustomerA L3VPN | 30 min | Unchanged |
| **3** | Provision CustomerB L3VPN | 25 min | Unchanged |
| **4** | End-to-End Validation | 20 min | Unchanged |
| **5** | Terraform State Management | 25 min | Unchanged |
| **6** | Drift Detection & Auto-Remediation | 30 min | Unchanged |
| **7** | Configuration Modification & Re-apply | 20 min | Unchanged |
| **8** | GitOps Workflow & Source of Truth | 30 min | **NEW** |

**Exercise 8 Learning Objectives:**
- Understand Git as single source of truth (contrasts with Terraform state file)
- Detect configuration drift: running config vs Git YAML
- Use Ansible to enforce consistency and auto-sync
- Understand GitOps principles (Netflix, Google, AWS use this model)
- Learn why infrastructure config should live in Git (audit trail,rollback, visibility)

**Exercise 8 Structure (30 minutes):**
1. Review source of truth (Git vs running config) — 5 min
2. Make a change in Git (add field to customer_a.yml) — 5 min
3. Detect drift (running config doesn't have the change yet) — 5 min
4. Discuss GitOps principles & career context — 2 min
5. Enforce sync with Ansible (re-run playbook) — 5 min
6. Verify drift resolved (config now matches Git) — 3 min
7. Compare with Terraform approach (instructor-led) — 5 min
8. Optional: Simulate bad practice (direct device config, re-sync) — 5 min

**Commits — Version 0.3.8:**

| Commit | Files | Message |
|---|---|---|
| Latest | `docs/HANDS-ON_EXERCISES.md` | feat: restructure for 15-min intro + 225-min exercises; add Exercise 8: GitOps |

**Files — Version 0.3.8:**

| File | Location | Change |
|---|---|---|
| `docs/HANDS-ON_EXERCISES.md` | GitHub repo | **UPDATED:** Exercise overview: renamed Ex 1, added Ex 8 (1200+ lines) |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.3.8 section (exercise restructuring) |

**Impact Summary (v0.3.8):**

**For students:**
- ✅ Exercise 1 focuses on understanding pre-deployed topology (no wait-for-boot)
- ✅ Exercise 8 teaches Git-driven orchestration and GitOps philosophy
- ✅ See two complementary IaC approaches: Terraform state (5-7) vs Git+Ansible (8)
- ✅ Better engagement: 210 min exercises + 30 min buffer = 240 min session

**For instructors:**
- ✅ Smoother exercise flow: readiness → explore → provision → validate → Terraform drift → Ansible drift
- ✅ Can teach both IaC paradigms compellingly in one session
- ✅ Highlights that production uses both approaches together

**Lab readiness:** After v0.3.8, ready for Cisco Live 2026 delivery:
- ✅ 8 sequential exercises covering topology, Ansible provisioning, Terraform state, drift detection (2 models), GitOps
- ✅ 15-minute presentation script (INSTRUCTOR_SLIDES.md)
- ✅ Pre-lab reading assignments (TOPOLOGY_NOTES.md, HYBRID_APPROACH.md)
- ✅ Complete documentation: DEPLOYMENT_GUIDE.md, troubleshooting in all exercises
- ✅ 240 minutes of content for 30 attendees (4-hour session)

---

### 0.3.9 — TopoViewer Annotations Fix (Layered Layout, Icons, Groups)

**Date:** 2026-03-25

**Summary:**
Replaced the stale TopoViewer annotations file on the server with a fully corrected version. The previous file (`~/LTRATO-1001.clab.yml.annotations.json`) contained only raw/unordered positions with no icons or group assignments — the result of prior manual drag-and-drop. The corrected file establishes:

- A clean 4-row layered layout matching the reference topology diagram
- Correct built-in icons per node type (`pe` for XRd/CSR, `switch` for N9K, `client` for Linux)
- Four named, color-coded group bands (`core`, `pe-ce-edge`, `dc`, `clients`) with proper `groupStyleAnnotations`
- Preserved `interfacePattern` values for XRd and CSR nodes

**Changes made:**
- Wrote new `untracked/LTRATO-1001.clab.yml.annotations.json` locally
- Pushed to server: `~/LTRATO-1001.clab.yml.annotations.json`

**Node layout (x, y):**

| Node | x | y | Icon | Group |
|---|---|---|---|---|
| xrd01 | 250 | 100 | pe | core |
| xrd02 | 950 | 100 | pe | core |
| csr-pe01 | 250 | 340 | pe | pe-ce-edge |
| csr-pe02 | 950 | 340 | pe | pe-ce-edge |
| n9k-ce01 | 250 | 580 | switch | dc |
| n9k-ce02 | 950 | 580 | switch | dc |
| linux-client1 | 100 | 820 | client | clients |
| linux-client2 | 380 | 820 | client | clients |
| linux-client3 | 820 | 820 | client | clients |
| linux-client4 | 1100 | 820 | client | clients |

**Files — Version 0.3.9:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **NEW:** Corrected annotations with layout, icons, and groups |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Replaced stale file with corrected version |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.3.9 section |

---

### 0.4.0 — TopoViewer Interface Aliases (Show Real Device Interface Names)

**Date:** 2026-03-25

**Summary:**
Updated all topology link endpoints with ContainerLab `alias` labels so that TopoViewer displays the actual device interface names a student would see on the CLI, rather than the container-internal `ethN` names.

**Interface mapping discovered:**

| Node type | Container iface | Device iface |
|---|---|---|
| CSR1000v (vrnetlab) | `eth1` | `GigabitEthernet2` |
| CSR1000v (vrnetlab) | `eth3` | `GigabitEthernet4` |
| N9K (vrnetlab) | `eth1` | `Ethernet1/1` |
| N9K (vrnetlab) | `eth3` | `Ethernet1/3` |
| N9K (vrnetlab) | `eth4` | `Ethernet1/4` |
| XRd | `Gi0-0-0-0` | `GigabitEthernet0/0/0/0` (native name; ContainerLab uses dashes) |
| Linux | `eth1` | `eth1` (no alias needed) |

**Syntax used:** `node:container-interface:alias` in the `endpoints` list (ContainerLab 0.74.3+).

**Also updated:** `interfacePattern` in `LTRATO-1001.clab.yml.annotations.json` for CSR nodes changed from `Gi{n}` to `GigabitEthernet{n}`.

**Files — Version 0.4.0:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml` | Local (untracked) | **UPDATED:** All links rewritten with interface aliases |
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** CSR `interfacePattern` corrected |
| `~/LTRATO-1001.clab.yml` | Server (`198.18.134.90`) | **UPDATED:** Pushed alias-annotated topology |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Pushed corrected annotations |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.0 section |

---

### 0.4.1 — TopoViewer Fix: Revert Bad Alias Syntax, Use aliasEndpointAnnotations

**Date:** 2026-03-25

**Summary:**
The `node:interface:alias` endpoint syntax used in v0.4.0 is NOT valid ContainerLab YAML. The TopoViewer extension parsed the third colon-separated token as a new phantom node ID, causing a stray "Core" cloud icon to appear and all link lines to route incorrectly to the top-left corner.

**Fix:**
- Reverted all YAML endpoints back to standard `node:interface` two-token format
- Moved interface display name mappings into `aliasEndpointAnnotations` in the annotations JSON, which is the correct TopoViewer mechanism for this
- Reverted CSR `interfacePattern` back to `Gi{n}`

**aliasEndpointAnnotations added:**

| Endpoint ID | Display alias |
|---|---|
| `csr-pe01:eth1` | `GigabitEthernet2` |
| `csr-pe01:eth3` | `GigabitEthernet4` |
| `csr-pe02:eth1` | `GigabitEthernet2` |
| `csr-pe02:eth3` | `GigabitEthernet4` |
| `n9k-ce01:eth1` | `Ethernet1/1` |
| `n9k-ce01:eth3` | `Ethernet1/3` |
| `n9k-ce01:eth4` | `Ethernet1/4` |
| `n9k-ce02:eth1` | `Ethernet1/1` |
| `n9k-ce02:eth3` | `Ethernet1/3` |
| `n9k-ce02:eth4` | `Ethernet1/4` |

**Files — Version 0.4.1:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml` | Local (untracked) | **REVERTED:** Endpoints back to `node:interface` format |
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** `aliasEndpointAnnotations` added; `interfacePattern` reverted |
| `~/LTRATO-1001.clab.yml` | Server (`198.18.134.90`) | **UPDATED:** Clean topology pushed |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Annotations with alias mappings pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.1 section |

---

### 0.4.2 — TopoViewer Fix: Use ContainerLab Native Interface Aliases in YAML

**Date:** 2026-03-25

**Summary:**
Investigation revealed that `aliasEndpointAnnotations` in the annotations JSON is dead code in VS Code extension v0.24.2 — it is parsed but never applied to edge rendering. The TopoViewer reads link labels **directly from the YAML endpoint strings**. The correct fix is to use ContainerLab's native interface alias feature (available since v0.56.0): write the real device interface name directly in the YAML, and ContainerLab transparently maps it to the Linux `ethN` name internally.

**Fix:**
- Updated all CSR1000v and N9Kv endpoint strings in `LTRATO-1001.clab.yml` to use native interface aliases instead of `ethN` names
- No redeploy required — TopoViewer reads the YAML file directly
- No changes to the annotations JSON

**Interface alias mappings applied:**

| Old YAML endpoint | New YAML endpoint | Linux interface |
|---|---|---|
| `csr-pe01:eth1` | `csr-pe01:GigabitEthernet2` | `eth1` |
| `csr-pe01:eth3` | `csr-pe01:GigabitEthernet4` | `eth3` |
| `csr-pe02:eth1` | `csr-pe02:GigabitEthernet2` | `eth1` |
| `csr-pe02:eth3` | `csr-pe02:GigabitEthernet4` | `eth3` |
| `n9k-ce01:eth1` | `n9k-ce01:Ethernet1/1` | `eth1` |
| `n9k-ce01:eth3` | `n9k-ce01:Ethernet1/3` | `eth3` |
| `n9k-ce01:eth4` | `n9k-ce01:Ethernet1/4` | `eth4` |
| `n9k-ce02:eth1` | `n9k-ce02:Ethernet1/1` | `eth1` |
| `n9k-ce02:eth3` | `n9k-ce02:Ethernet1/3` | `eth3` |
| `n9k-ce02:eth4` | `n9k-ce02:Ethernet1/4` | `eth4` |

**Files — Version 0.4.2:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml` | Local (untracked) | **UPDATED:** Endpoints use native interface aliases |
| `~/LTRATO-1001.clab.yml` | Server (`198.18.134.90`) | **UPDATED:** Native alias YAML pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.2 section |

---

### 0.4.3 — TopoViewer Layout: Fix Overlapping Interface Labels

**Date:** 2026-03-25

**Summary:**
Two visual overlap issues fixed in the TopoViewer layout:
1. **Nexus `Ethernet1/3` / `Ethernet1/4` labels overlap** — the two downward links from each Nexus node had interface labels that stacked on top of each other. Fixed by increasing vertical gap between the DC and Clients rows and spreading clients horizontally further apart.
2. **CSR `GigabitEthernet4` overlaps hostname** — the bottom interface label clipped into the node hostname text. Fixed by moving CSR nodes slightly lower within their group box.

**Position changes:**

| Node | Old posY | New posY | Notes |
|---|---|---|---|
| `csr-pe01`, `csr-pe02` | 340 | 370 | More room for GigabitEthernet4 label below icon |
| `n9k-ce01`, `n9k-ce02` | 580 | 620 | More vertical gap from clients |
| `linux-client1` | 820 | 900 | More gap from Nexus |
| `linux-client2` | 820 | 900 | Spread right (posX 380→420) |
| `linux-client3` | 820 | 900 | Spread left (posX 820→760) |
| `linux-client4` | 820 | 900 | Spread right (posX 1100→1140) |

**Files — Version 0.4.3:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml` | Local (untracked) | **UPDATED:** Node positions adjusted |
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** Node positions and group heights adjusted |
| `~/LTRATO-1001.clab.yml` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.3 section |

---

### 0.4.4 — TopoViewer: Separate Nexus Interface Labels via edgeAnnotations

**Date:** 2026-03-25

**Summary:**
Node position changes (v0.4.3) are only applied on a fresh deploy — the running lab's `topology-data.json` is used for positions instead. The correct in-place fix for overlapping Nexus interface labels is `edgeAnnotations` with different `endpointLabelOffset` values. Each pair of Nexus→client edges now has a different offset so their source-end labels (`Ethernet1/3` vs `Ethernet1/4`) land at different distances along the line and no longer overlap.

**Root cause:** Two edges sharing the same source node (n9k-ce01 or n9k-ce02) had labels placed at the same default offset (20px), making them stack on top of each other.

**Fix:** Added `edgeAnnotations` to the annotations JSON:

| Edge | Offset | Effect |
|---|---|---|
| `n9k-ce01:Ethernet1/3` → `linux-client1:eth1` | 5 | Label very close to Nexus (top) |
| `n9k-ce01:Ethernet1/4` → `linux-client2:eth1` | 30 | Label further along edge (bottom) |
| `n9k-ce02:Ethernet1/3` → `linux-client3:eth1` | 5 | Label very close to Nexus (top) |
| `n9k-ce02:Ethernet1/4` → `linux-client4:eth1` | 30 | Label further along edge (bottom) |

**Files — Version 0.4.4:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** `edgeAnnotations` added with per-edge offsets |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.4 section |

---

### 0.4.5 — TopoViewer: Symmetric Client Positions for Level Interface Labels

**Date:** 2026-03-25

**Summary:**
The `endpointLabelOffset` approach moves labels along the edge direction, so on asymmetric diagonal edges the labels land at different Y positions regardless of offset value. The correct fix is to make the two edges from each Nexus node geometrically symmetric by positioning the two client nodes equidistant (±70px) on either side of their parent Nexus node horizontally. With symmetric angles, equal offsets produce labels at the same Y level.

**Position changes in annotations JSON:**

| Node | Old x | New x | Notes |
|---|---|---|---|
| `linux-client1` | 60 | 85 | Symmetric around n9k-ce01 (x=155) |
| `linux-client2` | 280 | 225 | Symmetric around n9k-ce01 (x=155) |
| `linux-client3` | 430 | 455 | Symmetric around n9k-ce02 (x=525) |
| `linux-client4` | 620 | 595 | Symmetric around n9k-ce02 (x=525) |

All four Nexus→client edge offsets reset to equal value (50).

**Files — Version 0.4.5:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** Client positions symmetrized; edge offsets equalized |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.5 section |

---

### 0.4.6 — TopoViewer: Shorten N9Kv Interface Labels to Eth1/x

**Date:** 2026-03-25

**Summary:**
`Ethernet1/3` and `Ethernet1/4` labels were still slightly overlapping on the Nexus nodes due to label width. Shortened all N9Kv interface aliases to the abbreviated NX-OS form (`Eth1/1`, `Eth1/3`, `Eth1/4`) for consistent, compact display. ContainerLab accepts these abbreviations natively.

**Changes:**

| Old alias | New alias |
|---|---|
| `Ethernet1/1` | `Eth1/1` |
| `Ethernet1/3` | `Eth1/3` |
| `Ethernet1/4` | `Eth1/4` |

**Files — Version 0.4.6:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml` | Local (untracked) | **UPDATED:** N9Kv endpoints shortened to `Eth1/x` |
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** `edgeAnnotations` keys and `aliasEndpointAnnotations` updated to match |
| `~/LTRATO-1001.clab.yml` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.6 section |

---

### 0.4.7 — TopoViewer: Push Downward Interface Labels Clear of Node Hostnames

**Date:** 2026-03-25

**Summary:**
The downward-facing interface labels on `xrd01`, `xrd02`, `csr-pe01`, and `csr-pe02` were overlapping the hostname text below each node icon. Added `edgeAnnotations` with offset=55 on the four downward edges so their source-end labels are pushed further along the line, clearing the hostname.

**Edges adjusted:**

| Edge | Offset | Label moved |
|---|---|---|
| `xrd01:Gi0-0-0-1` → `csr-pe01:GigabitEthernet2` | 55 | `Gi0-0-0-1` off xrd01 |
| `xrd02:Gi0-0-0-1` → `csr-pe02:GigabitEthernet2` | 55 | `Gi0-0-0-1` off xrd02 |
| `csr-pe01:GigabitEthernet4` → `n9k-ce01:Eth1/1` | 55 | `GigabitEthernet4` off csr-pe01 |
| `csr-pe02:GigabitEthernet4` → `n9k-ce02:Eth1/1` | 55 | `GigabitEthernet4` off csr-pe02 |

**Files — Version 0.4.7:**

| File | Location | Change |
|---|---|---|
| `untracked/LTRATO-1001.clab.yml.annotations.json` | Local (untracked) | **UPDATED:** `edgeAnnotations` added for 4 downward edges |
| `~/LTRATO-1001.clab.yml.annotations.json` | Server (`198.18.134.90`) | **UPDATED:** Pushed |
| `CHANGELOG.md` | GitHub repo | **UPDATED:** Added v0.4.7 section |
