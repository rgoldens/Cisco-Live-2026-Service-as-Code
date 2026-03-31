# LTRATO-1001 Lab — Findings, Fixes & Task 3 Build-Out

**Lab**: Cisco Live 2026 — *Service as Code* (LTRATO-1001)  
**Date**: March 31, 2026  
**Environment**: Containerlab 0.74.3 on Ubuntu  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Lab Topology & Addressing](#2-lab-topology--addressing)
3. [Findings — Startup Configurations](#3-findings--startup-configurations)
4. [Findings — Task 2 Playbooks (ISIS)](#4-findings--task-2-playbooks-isis)
5. [Findings — Task 2 Master Playbook](#5-findings--task-2-master-playbook)
6. [Findings — Task 3 README](#6-findings--task-3-readme)
7. [Findings — Infrastructure / Operational](#7-findings--infrastructure--operational)
8. [Task 3 Build-Out](#8-task-3-build-out)
9. [Fix Summary](#9-fix-summary)
10. [Recommendations for Cisco Live Delivery](#10-recommendations-for-cisco-live-delivery)

---

## 1. Executive Summary

End-to-end testing of the lab (Tasks 1→2→3) uncovered **critical issues** in startup
configurations, playbook syntax, and documentation. The lab would **not work
as-shipped** for students. All issues have been identified and fixes applied.

**Key problem categories:**

| Category | Severity | Count |
|----------|----------|-------|
| Startup config — wrong interface mapping | Critical | 4 configs |
| Startup config — wrong IP scheme | Critical | 6 configs |
| Startup config — pre-configured services defeating lab objectives | Design | 4 configs |
| Playbook syntax — silent IOS-XE errors | Critical | 4 bugs |
| Playbook structure — `include_tasks` vs `import_playbook` | Critical | 1 bug |
| Documentation — wrong architecture description | Major | 1 file |
| Infrastructure — vrnetlab fragility with `docker stop/start` | Operational | 1 issue |

---

## 2. Lab Topology & Addressing

### Containerlab Wiring (from `LTRATO-1001.clab.yml`)

```
xrd01 (Gi0/0/0/0)  ↔  (Gi0/0/0/0) xrd02         P–P backbone
xrd01 (Gi0/0/0/1)  ↔  (Gi2/eth1)  csr-pe01       P–PE west
xrd02 (Gi0/0/0/1)  ↔  (Gi2/eth1)  csr-pe02       P–PE east
csr-pe01 (Gi4/eth3) ↔  (Eth1/1)   n9k-ce01       PE–CE west
csr-pe02 (Gi4/eth3) ↔  (Eth1/1)   n9k-ce02       PE–CE east
n9k-ce01 (Eth1/3)  ↔  linux-client1               client west
n9k-ce01 (Eth1/4)  ↔  linux-client2               client west
n9k-ce02 (Eth1/3)  ↔  linux-client3               client east
n9k-ce02 (Eth1/4)  ↔  linux-client4               client east
```

> **CSR vrnetlab mapping**: eth1→Gi2, eth2→Gi3, eth3→Gi4

### Correct IP Addressing (after fix)

| Device | Loopback0 | Backbone/Uplink | PE-CE/Downlink |
|--------|-----------|-----------------|----------------|
| xrd01 | 192.168.0.1/32 | Gi0/0/0/0 = 10.0.0.1/30 | Gi0/0/0/1 = 10.1.0.5/30 |
| xrd02 | 192.168.0.2/32 | Gi0/0/0/0 = 10.0.0.2/30 | Gi0/0/0/1 = 10.1.0.9/30 |
| csr-pe01 | 192.168.10.11/32 | Gi2 = 10.1.0.6/30 | Gi4 = 10.2.0.1/30 |
| csr-pe02 | 192.168.10.12/32 | Gi2 = 10.1.0.10/30 | Gi4 = 10.2.0.5/30 |
| n9k-ce01 | 10.0.0.21/32 | — | Eth1/1 = 10.2.0.2/30 |
| n9k-ce02 | 10.0.0.22/32 | — | Eth1/1 = 10.2.0.6/30 |

---

## 3. Findings — Startup Configurations

### 3.1 CSR Startup Configs — Wrong Interface Mapping (CRITICAL)

**Files**: `configs/csr-pe01.cfg.bak`, `configs/csr-pe02.cfg.bak`

The original CSR configs had interface descriptions and IP assignments that **did not
match the containerlab wiring**:

| Interface | Original Config Said | Actual Containerlab Wiring |
|-----------|---------------------|---------------------------|
| Gi2 (eth1) | `TO_n9k-ce01_Eth1/1` (CE link) | → xrd01 Gi0/0/0/1 (backbone) |
| Gi3 (eth2) | `TO_xrd01_Gi0-0-0-1` (backbone) | → csr-pe02 Gi3 (inter-PE) |
| Gi4 (eth3) | `TO_csr-pe02_Gi4` (inter-PE) | → n9k-ce01 Eth1/1 (CE link) |

**Impact**: All ISIS adjacencies, MPLS LDP, and BGP VPN sessions would form on the
wrong interfaces. The SP backbone would be wired through the CE-facing port and
vice versa.

**Fix**: Rewrote both CSR configs with correct interface-to-neighbor mapping:
- Gi2 → XRd (backbone uplink)
- Gi3 → inter-PE (unused)
- Gi4 → N9K-CE (CE-facing downlink)

### 3.2 All Configs — Wrong IP Addressing Scheme (CRITICAL)

The original configs used `10.0.0.x` loopbacks while the playbooks expected
`192.168.x.x` loopbacks:

| Device | Original Loopback0 | Playbook Expected |
|--------|--------------------|-------------------|
| xrd01 | 10.0.0.1 | 192.168.0.1 |
| xrd02 | 10.0.0.2 | 192.168.0.2 |
| csr-pe01 | 10.0.0.11 | 192.168.10.11 |
| csr-pe02 | 10.0.0.12 | 192.168.10.12 |

**Impact**: BGP neighbor statements in Task 3 playbooks (neighbor 192.168.0.1,
192.168.10.11, etc.) would never establish sessions because devices had different IPs.

**Fix**: Updated all startup configs and the live containerlab XRd configs
(`/home/cisco/xrd01-startup.cfg`, `/home/cisco/xrd02-startup.cfg`) to use the
`192.168.x.x` scheme that matches the playbooks.

### 3.3 Configs — Pre-configured Services Defeating Lab Objectives (DESIGN)

**Files**: All 6 original configs

The original startup configurations had full ISIS, MPLS LDP, BGP, VRF, OSPF,
VXLAN, and EVPN pre-configured. This **defeats the purpose of the lab** — students
are supposed to configure these services via Ansible playbooks.

| Device | Pre-configured (should not be) |
|--------|-------------------------------|
| CSR PEs | ISIS CORE, MPLS LDP, BGP 65000 with VPNv4, VRF CUST_A/CUST_B |
| XRd P-routers | MPLS LDP, BGP 65000 with VPNv4 + L2VPN EVPN, RR client configs |
| N9K CEs | OSPF UNDERLAY, BGP 65100 with L2VPN EVPN, VXLAN NVE, VNI 10100 |

**Fix**: Stripped all protocol configuration that is deployed by Tasks 2 and 3:
- **XRd**: Kept only ISIS CORE on backbone (Gi0/0/0/0 + Lo0). Removed MPLS LDP,
  BGP, L2VPN EVPN. Task 3 playbook deploys these.
- **CSR**: Removed all routing protocol config. Only Lo0 + interface IPs remain.
  Task 2 deploys ISIS, Task 3 deploys MPLS + BGP + VRF.
- **N9K**: Removed OSPF, BGP, VXLAN, EVPN, NVE, VNI. Only basic features +
  interface IPs remain. Task 2 deploys ISIS CUSTOMER.

### 3.4 XRd Original Config — Duplicate IP on Loopback and Gi0/0/0/0

**File**: `configs/xrd01.cfg.bak`

```
interface Loopback0
 ipv4 address 10.0.0.1 255.255.255.255
interface GigabitEthernet0/0/0/0
 ipv4 address 10.0.0.1 255.255.255.252    ← Same IP as Loopback!
```

Both Loopback0 and Gi0/0/0/0 had `10.0.0.1`. While IOS-XR allows overlapping /32
and /30, this is a configuration error and would cause routing ambiguity.

**Fix**: Loopback0 = 192.168.0.1/32, Gi0/0/0/0 = 10.0.0.1/30 (different subnets).

### 3.5 N9K Original Config — Unnecessary Feature Bloat

The original N9K configs enabled features that aren't needed for the lab and could
confuse students:

```
feature netconf
feature nxapi
feature grpc
feature bgp
feature ospf
feature vn-segment-vlan-based
feature nv overlay
```

**Fix**: Trimmed to only features needed: `ssh`, `scp-server`, `interface-vlan`, `lacp`.

---

## 4. Findings — Task 2 Playbooks (ISIS)

### 4.1 Invalid ISIS NET Format (CRITICAL — Silent Failure)

**File**: `Task2/playbooks/01_deploy_isis_csr.yml` (original)

```
net 49.0000001.0000.0000.0011.00
```

This NET (Network Entity Title) has too many bytes. CLNS NETs must follow the
format `AA.BBBB.CCCC.CCCC.CCCC.00` where the system ID is exactly 6 bytes
(3 groups of 4 hex digits). The original had 7 groups.

IOS-XE reports `% Incomplete command` but the `shell` module's SSH wrapper
has rc=0 as long as the SSH session succeeded → **error is silently ignored**.

**Fix**: Changed to proper NET derived from the loopback IP:
- csr-pe01: `49.0001.1921.6810.0011.00` (derived from 192.168.10.11)
- csr-pe02: `49.0001.1921.6810.0012.00` (derived from 192.168.10.12)

### 4.2 Invalid `is-type level-1-only` Syntax (CRITICAL — Silent Failure)

```yaml
is-type level-1-only    # ← WRONG
```

IOS-XE accepts `is-type level-1`, `is-type level-2-only`, or `is-type level-1-2`.
There is no `level-1-only` keyword. IOS-XE returns `% Invalid input` but the
shell module doesn't catch it.

**Fix**: Changed to `is-type level-1` for customer instances and `is-type level-2-only`
for CORE.

### 4.3 Invalid `passive-interface Loopback0` Under `router isis` (CRITICAL — Silent Failure)

```yaml
router isis CORE
 passive-interface Loopback0    # ← WRONG
```

IOS-XE ISIS does **not** support `passive-interface` as a sub-command under
`router isis`. This is different from OSPF. In ISIS, passiveness is implicit:
Loopback0 gets `ip router isis CORE` at the interface level, but since no
adjacency can form on a loopback, it naturally acts as passive.

**Fix**: Removed `passive-interface Loopback0` entirely. Added a separate task to
apply `ip router isis CORE` under `interface Loopback0`.

### 4.4 `ip router isis CORE` Fails Without Interface IP (CRITICAL — Silent Failure)

The original CSR startup configs had no IP on Gi2, Gi4, or Lo0 (or wrong IPs).
When the playbook pushes `ip router isis CORE` on an interface without an IP:

```
% Cannot enable ISIS-IP. Configure IP address first.
```

This also goes undetected by the shell module.

**Fix**: Two-pronged:
1. Fixed startup configs to pre-configure correct IPs on all interfaces.
2. Added `failed_when` to every shell task to detect IOS error strings:
   ```yaml
   failed_when: "'Invalid input' in result.stdout or 'Cannot enable' in result.stdout"
   ```

### 4.5 No Error Detection on Shell Tasks (CRITICAL)

Every `shell` task that SSHs into the CSR had **no `failed_when` clause**. Because
the `shell` module checks the SSH client's return code (always 0 if SSH connects),
IOS-XE configuration errors are completely invisible to Ansible.

A playbook run that looks like this is misleading:
```
ok: [csr-pe01] => Step 1: Configure ISIS CORE ← actually failed silently
ok: [csr-pe02] => Step 1: Configure ISIS CORE ← actually failed silently
```

**Fix**: Added `failed_when` to all CSR shell tasks, checking stdout for:
- `Invalid input` (bad command syntax)
- `Incomplete` (truncated commands)
- `Cannot enable` (missing prerequisite like IP address)

### 4.6 Missing `isis network point-to-point` on CSR Gi2 (MAJOR)

The original playbook configured ISIS on CSR Gi2 but did not set P2P network type.
By default, IOS-XE uses **broadcast** mode for ISIS on Ethernet interfaces.
XRd's Gi0/0/0/1 was configured as `point-to-point`. This creates a
**P2P vs broadcast mismatch** — ISIS adjacency never forms.

**Fix**: Added `isis network point-to-point` to the Gi2 configuration step.

### 4.7 Missing ISIS CUSTOMER Instance in Fixed Playbook

The original playbook configured both ISIS CORE and ISIS CUSTOMER instances.
When the playbook was initially rewritten, the CUSTOMER instance was accidentally
dropped (only CORE was included).

**Fix**: Re-added the full CUSTOMER_RED / CUSTOMER_PURPLE configuration including:
- Router process with correct NET and `is-type level-1`
- `ip router isis CUSTOMER_x` on GigabitEthernet4 (CE-facing)
- `ip router isis CUSTOMER_x` on Loopback0

---

## 5. Findings — Task 2 Master Playbook

### 5.1 `include_tasks` Used on Files Containing Full Plays (CRITICAL)

**File**: `Task2/playbooks/00_deploy_task2.yml` (original)

```yaml
tasks:
  - name: Include CSR deployment playbook
    include_tasks: 01_deploy_isis_csr.yml
    when: inventory_hostname.startswith('csr')
```

`include_tasks` can only import **task lists** (a flat list of tasks without
`hosts:`, `vars:`, etc.). The included files (`01_deploy_isis_csr.yml`,
`02_deploy_isis_nxos.yml`) are **full plays** with their own `hosts:` directives.

This causes:
```
ERROR! conflicting action statements: hosts, tasks
```

**Fix**: Changed to `import_playbook` at the play level:
```yaml
- import_playbook: 01_deploy_isis_csr.yml
- import_playbook: 02_deploy_isis_nxos.yml
```

Also restructured to remove the single-play wrapper (since `import_playbook` must
be at the top level, not inside a play).

---

## 6. Findings — Task 3 README

### 6.1 README Describes Wrong Architecture (MAJOR)

**File**: `Task3/README.md`

The README described **Inter-AS Option A** with:
- CSR-PE01 in ASN 65001, CSR-PE02 in ASN 65002
- eBGP between XRd (65000) and CSRs (65001/65002)
- Two separate autonomous systems

**Actual design** (as implemented in the playbooks):
- All devices in **ASN 65000** (single iBGP domain)
- XRd01/XRd02 = **Route Reflectors**
- CSR-PE01/PE02 = **RR Clients**
- iBGP VPNv4 with `update-source Loopback0`

**Fix**: Completely rewrote the README to accurately describe:
- Single iBGP AS 65000 with Route Reflectors
- Correct topology diagram with interface names
- Accurate playbook descriptions and run sequence
- Expected end state after Task 3 completion

---

## 7. Findings — Infrastructure / Operational

### 7.1 vrnetlab Containers Break on `docker stop/start` (CRITICAL)

During testing, CSR containers were restarted with `docker stop/start`. This
**destroyed the data plane**:

1. Containerlab veth links (ethX) are destroyed by `docker stop`
2. `docker start` recreates the container but doesn't recreate veth links
3. Only eth0 (management) survives because Docker manages it
4. vrnetlab's internal bridges (ethX → QEMU socket) are also destroyed
5. Even `containerlab tools veth create` can't fully fix it because QEMU's
   internal `-netdev socket,listen=:1000X` connections are lost

**Only solution**: Full `containerlab destroy + deploy` cycle:
```bash
containerlab destroy -t /home/cisco/LTRATO-1001.clab.yml --keep-mgmt-net
containerlab deploy -t /home/cisco/LTRATO-1001.clab.yml
```

**Recommendation**: Add a WARNING to the lab guide: "Never use `docker stop/start`
on lab containers. Always use `containerlab destroy/deploy`."

### 7.2 SSH Host Keys Change After Redeploy

After every `containerlab destroy/deploy`, all device SSH host keys change.
Students will get `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` errors.

**Fix**: Clear known_hosts after any redeploy:
```bash
for ip in 172.20.20.{10,11,20,21,30,31}; do ssh-keygen -R $ip; done
for h in xrd01 xrd02 csr-pe01 csr-pe02 n9k-ce01 n9k-ce02; do
  ssh-keygen -R clab-LTRATO-1001-$h
done
```

**Recommendation**: Add this as a helper script or documented step.

### 7.3 CSR Legacy SSH KEX Requirements

CSR1000v 16.12 requires legacy SSH algorithms. Ansible's paramiko doesn't support
all of them, which is why playbooks use `connection: local` + `shell` with raw SSH.

Required SSH options:
```
-o HostKeyAlgorithms=ssh-rsa
-o PubkeyAcceptedKeyTypes=ssh-rsa
-o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
```

### 7.4 Topology File Location Confusion

Two topology files exist:
- `/home/cisco/LTRATO-1001.clab.yml` — **Active** (used by containerlab)
- `/tmp/.../topology/sac-lab.yml` — **Stale/unused**

Running `containerlab destroy` against the wrong file causes confusion and doesn't
actually stop the running lab.

**Recommendation**: Remove or clearly mark the stale topology file.

### 7.5 CSR/N9K Have No `startup-config` in Topology File

Only XRd nodes have `startup-config:` directives in `LTRATO-1001.clab.yml`.
CSR and N9K containers boot with default/empty configs (vrnetlab saves config
to its internal flash, but on a fresh deploy there's nothing).

This means after every `containerlab destroy/deploy`:
- XRd boots with correct IPs and ISIS CORE ✅
- CSR boots bare — no IPs, no routing ❌
- N9K boots with just a hostname ❌

**Impact**: Students must either:
1. Run a "bootstrap" playbook to push base IPs before Task 2/3 can work, OR
2. The topology file needs `startup-config:` for CSR/N9K nodes

**Recommendation**: Add CSR and N9K startup configs to the containerlab topology:
```yaml
csr-pe01:
  kind: cisco_csr1000v
  startup-config: csr-pe01-startup.cfg    # ← add this
n9k-ce01:
  kind: cisco_n9kv
  startup-config: n9k-ce01-startup.cfg    # ← add this
```

---

## 8. Task 3 Build-Out

### 8.1 Architecture

Task 3 builds an MPLS L3VPN service across the SP core:

```
                    [ASN 65000 — iBGP VPNv4]

  N9K-CE01 ── Gi4 ── CSR-PE01 ── Gi2 ── XRd01 ═══ XRd02 ── Gi2 ── CSR-PE02 ── Gi4 ── N9K-CE02
  (ISIS CUST_RED)     (VRF CUST_A)       (RR)      (RR)      (VRF CUST_A)     (ISIS CUST_PURPLE)
```

- **XRd01/XRd02**: P-Routers + Route Reflectors (VPNv4)
- **CSR-PE01/PE02**: PE Routers (RR clients), VRF CUST_A on CE-facing Gi4
- **N9K-CE01/CE02**: CE switches with ISIS CUSTOMER peering to PE

### 8.2 Prerequisites (from Task 2)

Task 3 depends on Task 2 having deployed:
- ISIS CORE on CSR Gi2 + Lo0 (backbone connectivity to XRd)
- ISIS CUSTOMER_RED / CUSTOMER_PURPLE on CSR Gi4 + N9K Eth1/1

### 8.3 Playbook 1: `01_deploy_underlay.yml`

**Play 1 — XRd (ISIS + MPLS LDP):**
- Adds Gi0/0/0/1 to ISIS CORE (P-PE links join the backbone)
- Configures MPLS LDP with router-id = Loopback0
- Enables MPLS LDP on both Gi0/0/0/0 (backbone) and Gi0/0/0/1 (PE link)

**Play 2 — CSR (MPLS LDP):**
- Configures `mpls ldp router-id Loopback0 force`
- Enables `mpls ip` on Gi2 (backbone uplink)
- Adds `isis network point-to-point` on Gi2 (matches XRd P2P mode)

**Play 3 — Validation:**
- Shows ISIS neighbors on XRd (expect 2: other XRd + CSR PE)
- Shows MPLS LDP neighbor summary

### 8.4 Playbook 2: `02_deploy_overlay.yml`

**Play 1 — XRd Route Reflectors (BGP VPNv4):**
- Configures BGP 65000 with router-id = Loopback0
- Enables VPNv4 address-family
- Adds neighbors:
  - Other XRd (full mesh, not RR client)
  - Both CSR PEs (RR clients with `route-reflector-client`)
- All neighbors use `update-source Loopback0`

**Play 2 — CSR PE Routers (BGP VPNv4 + VRF):**
- Creates VRF CUST_A (RD 65000:100, RT 65000:100)
- Places Gi4 into VRF CUST_A (⚠️ this strips Task 2's ISIS CUSTOMER from Gi4)
- Re-applies Gi4 IP address after VRF assignment
- Configures BGP 65000 with VPNv4 to both XRd RRs
- Enables `address-family ipv4 vrf CUST_A` with `redistribute connected`

**Play 3 — Validation:**
- Shows BGP VPNv4 summary on XRd (expect Established sessions to CSR PEs)

### 8.5 Playbook 3: `03_validate_task3.yml`

**Play 1 — XRd Validation:**
- ISIS neighbors (assert "Up" present)
- MPLS LDP neighbors (assert non-empty)
- BGP VPNv4 summary
- Full IPv4 route table

**Play 2 — CSR Validation:**
- ISIS neighbors, MPLS LDP neighbors
- BGP VPNv4 summary
- VRF table, VRF routes
- Interface status

**Play 3 — Reachability:**
- Ping from XRd01 to CSR PE loopbacks (192.168.10.11, 192.168.10.12)

**Play 4 — Summary checklist:**
- Visual checklist for students to verify all components

### 8.6 Design Note: VRF Assignment Strips ISIS CUSTOMER

When Task 3's overlay playbook assigns Gi4 to `vrf forwarding CUST_A`, IOS-XE
automatically removes any existing IP address and ISIS configuration from that
interface. This is by IOS-XE design.

This means Task 2's `ip router isis CUSTOMER_RED` on Gi4 is destroyed. The PE-CE
routing moves from flat ISIS to L3VPN — which is the intended lab progression:

- **After Task 2**: PE-CE uses flat ISIS (CUSTOMER_RED/PURPLE instances)
- **After Task 3**: PE-CE uses MPLS L3VPN (VRF CUST_A with connected redistribution)

---

## 9. Fix Summary

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `configs/csr-pe01.cfg` | Rewritten | Correct interface mapping, 192.168.x IPs, no pre-config |
| `configs/csr-pe02.cfg` | Rewritten | Same pattern for PE02 |
| `configs/xrd01.cfg` | Rewritten | 192.168.x IPs, ISIS CORE backbone only |
| `configs/xrd02.cfg` | Rewritten | Same pattern for xrd02 |
| `configs/n9k-ce01.cfg` | Rewritten | Stripped OSPF/BGP/VXLAN/EVPN, kept only basics |
| `configs/n9k-ce02.cfg` | Rewritten | Same pattern for CE02 |
| `/home/cisco/xrd01-startup.cfg` | Updated | Live XRd config with correct IPs + ISIS CORE |
| `/home/cisco/xrd02-startup.cfg` | Updated | Same for xrd02 |
| `Task2/playbooks/01_deploy_isis_csr.yml` | Rewritten | Fixed NET, is-type, removed passive-interface, added P2P, added failed_when |
| `Task2/playbooks/00_deploy_task2.yml` | Rewritten | Changed include_tasks to import_playbook |
| `Task3/README.md` | Rewritten | Corrected architecture from eBGP Inter-AS to iBGP RR |

### Backups

Original configs backed up as `*.cfg.bak` in `configs/` directory.

### Files Created (Task 3)

| File | Purpose |
|------|---------|
| `Task3/playbooks/01_deploy_underlay.yml` | ISIS PE links + MPLS LDP deployment |
| `Task3/playbooks/02_deploy_overlay.yml` | BGP VPNv4 + VRF CUST_A deployment |
| `Task3/playbooks/03_validate_task3.yml` | End-to-end validation with assertions |
| `Task3/README.md` | Accurate architecture documentation |

---

## 10. Recommendations for Cisco Live Delivery

### P0 — Must Fix Before Lab

1. **Add `startup-config` for CSR/N9K in topology file** — Without this, every
   `containerlab deploy` produces bare CSRs with no IPs, and Task 2 playbooks fail
   because `ip router isis` requires an IP address on the interface first.

2. **Deploy and test the full sequence end-to-end** — Task 1 → Task 2 → Task 3
   with the fixed configs and playbooks, starting from a fresh `containerlab deploy`.

3. **Add `failed_when` to all CSR shell tasks** — The shell+SSH pattern hides all
   IOS-XE errors. Students will think things worked when they didn't. Every shell
   task that configures via SSH must check stdout for error indicators.

### P1 — Should Fix

4. **Create a bootstrap/reset playbook** — If the CSR/N9K startup-config approach
   doesn't work reliably with vrnetlab, provide a "Task 0" playbook that pushes
   base interface IPs to CSR/N9K after boot.

5. **Add a lab helper script** for SSH key cleanup after redeploy.

6. **Remove the stale `sac-lab.yml`** topology file to avoid confusion.

7. **Consider upgrading CSR to C8000v** if a newer image is available — this would
   eliminate the legacy SSH KEX workarounds and allow proper Ansible `network_cli`
   connection instead of shell+SSH hacks.

### P2 — Nice to Have

8. **Add timing expectations** to READMEs — CSR/N9K take ~5-7 minutes to boot
   after deploy. Students will think something is broken.

9. **Add a pre-flight check playbook** that verifies all devices are reachable
   and have expected base IPs before starting any task.

10. **Standardize the validation approach** — Task 3 has assertions with
    `assert` module; Task 2 should have the same pattern.

---

*End of document*
