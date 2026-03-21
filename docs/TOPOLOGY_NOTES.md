# LTRATO-1001 Topology Details

## Overview

**LTRATO-1001** is a 10-node containerlab topology representing a service provider network with L3VPN and EVPN capabilities.

**Deploy time:** ~3 minutes (container creation + boot)  
**Typical boot time:** 5-10 minutes (XRd and N9Kv are slowest)  
**Total runtime:** 26+ hours stable (suitable for extended sessions)

---

## Node Details

### Core (P-Routers) — IOS-XR (XRd)

All route reflector (RR) functionality is on P-routers, enabling hub-and-spoke VPNv4 BGP design.

| Node | Image | IP | Username | Password | Role | CPU | Memory |
|------|-------|----|-----------|-----------:|------|-----|--------|
| **xrd01** | `ios-xr/xrd-control-plane:25.1.1` | `172.20.20.10` | `clab` | `clab@123` | P/RR | 2 | 3 GB |
| **xrd02** | `ios-xr/xrd-control-plane:25.1.1` | `172.20.20.11` | `clab` | `clab@123` | P/RR | 2 | 3 GB |

**Pre-configured (startup config):**
- IS-IS underlay routing
- LDP label distribution  
- BGP Route Reflector (VPNv4 address-family)
- Loopback0: `10.0.0.1/32` (xrd01), `10.0.0.2/32` (xrd02)

**Key commands:**
```
show bgp vpnv4 unicast summary
show route-policy
show isis neighbors
```

---

### Edge (PE Routers) — IOS-XE (CSR1000v)

Provider Edge routers terminate customer VRFs and advertise routes to RRs.

| Node | Image | IP | Username | Password | Role | CPU | Memory |
|------|-------|----|-----------|-----------:|------|-----|--------|
| **csr-pe01** | `vrnetlab/vr-csr:17.03.06` | `172.20.20.20` | `admin` | `admin` | PE | 2 | 2 GB |
| **csr-pe02** | `vrnetlab/vr-csr:17.03.06` | `172.20.20.21` | `admin` | `admin` | PE | 2 | 2 GB |

**Pre-configured (startup config):**
- IS-IS underlay routing
- LDP label distribution
- BGP VPNv4 neighbor relationships to RRs
- Loopback0: `10.0.0.3/32` (pe01), `10.0.0.4/32` (pe02)

**Provisioned by Ansible (Hour 2):**
- VRF definitions (CUST_A, CUST_B)
- Route Targets (RT export/import)
- BGP in VRF context  
- PE-facing interface IPs (GigabitEthernet3 toward CE)

**Key commands:**
```
show vrf                           # List configured VRFs
show bgp vpnv4 unicast all summary # Neighbor status across all VRFs
show ip bgp vpnv4 all next-hop-unchanged
```

---

### Access (CE Switches) — NX-OS (N9Kv)

Customer Edge switches (represented as DC leaf switches) connect to PEs and test clients.

| Node | Image | IP | Username | Password | Role | CPU | Memory |
|------|-------|----|-----------|-----------:|------|-----|--------|
| **n9k-ce01** | `vrnetlab/vr-n9kv:10.4.3` | `172.20.20.30` | `admin` | `admin` | CE/DC | 1 | 2 GB |
| **n9k-ce02** | `vrnetlab/vr-n9kv:10.4.3` | `172.20.20.31` | `admin` | `admin` | CE/DC | 1 | 2 GB |

**Pre-configured (startup config):**
- OSPF underlay routing  
- Loopback0: `10.0.100.1/32` (ce01), `10.0.100.2/32` (ce02)

**Provisioned by Ansible (Hour 2):**
- VLAN interfaces for customer subnets
- BGP EBGP neighbor to PE
- EVPN NVE configuration (optional, Hour 3+)

**Key commands:**
```
show vlan id 100                   # Customer VLANs
show ip bgp summary                # BGP neighbor status
show nve interface nve 1           # VXLAN NVE status (if EVPN)
```

---

### Test Clients — Linux (Alpine)

Lightweight Alpine-based containers that generate test traffic and validate end-to-end connectivity.

| Node | Image | IP | Username | Notes |
|------|-------|----|-----------:|-----------|
| **linux-client1** | `ghcr.io/hellt/network-multitool:latest` | `172.20.20.40` | `root` / `admin` | Connected to n9k-ce01:eth3 |
| **linux-client2** | `ghcr.io/hellt/network-multitool:latest` | `172.20.20.41` | `root` / `admin` | Connected to n9k-ce02:eth3 |
| **linux-client3** | `ghcr.io/hellt/network-multitool:latest` | `172.20.20.42` | `root` / `admin` | Connected to n9k-ce01:eth4 |
| **linux-client4** | `ghcr.io/hellt/network-multitool:latest` | `172.20.20.43` | `root` / `admin` | Connected to n9k-ce02:eth4 |

**Pre-configured:**
- SSH daemon (ed25519 key-based auth)
- iperf, ping, curl, tcpdump pre-installed
- IP routes configured by provisioning playbooks

**Key commands (inside container):**
```
ping 192.168.100.10                # Test connectivity through L3VPN
iperf3 -s                          # Start iperf server
tcpdump -i eth0 -n icmp            # Sniff traffic
ip route show                      # Check routing table
```

---

## Network Architecture

### Management Network (172.20.20.0/24)

All nodes have a single management interface on the `clab` network.

```
┌─────────────────────────────────────────┐
│ Lab Host Docker Network (172.20.20.0/24)│
│                                          │
│  .10, .11      .20, .21      .30, .31  │
│   (XRd)         (CSR)         (N9Kv)    │
│   ▼▼            ▼▼            ▼▼        │
├────┴───────────────────────────────────┤
│   .40, .41, .42, .43 (Linux clients)   │
└─────────────────────────────────────────┘
```

### Data Plane Links (Inter-node)

All data links use containerlab's native Docker networking. Interface names are described in [../topology/sac-lab.yml](../topology/sac-lab.yml).

| From | To | Link Type |
|------|----|-----------:|
| xrd01:Gi0-0-0-0 | xrd02:Gi0-0-0-0 | P-to-P core mesh |
| xrd01:Gi0-0-0-1 | csr-pe01:eth1 | P-to-PE uplink |
| xrd02:Gi0-0-0-1 | csr-pe02:eth1 | P-to-PE uplink |
| csr-pe01:eth2 | csr-pe02:eth2 | Inter-PE (on-path redundancy) |
| csr-pe01:eth3 | n9k-ce01:eth1 | PE-to-CE primary link |
| csr-pe02:eth3 | n9k-ce02:eth1 | PE-to-CE primary link |
| n9k-ce01:eth2 | n9k-ce02:eth2 | CE-to-CE DC backbone  |
| n9k-ce01:eth3 | linux-client1:eth1 | CE-to-client1 |
| n9k-ce01:eth4 | linux-client3:eth1 | CE-to-client3 |
| n9k-ce02:eth3 | linux-client2:eth1 | CE-to-client2 |
| n9k-ce02:eth4 | linux-client4:eth1 | CE-to-client4 |

---

## IP Address Plan

### Loopback Addresses (Router IDs / BGP RRs)

```
10.0.0.0/24 — Loopback (BGP RR addresses)
├── 10.0.0.1/32  (xrd01-RR)
├── 10.0.0.2/32  (xrd02-RR)
├── 10.0.0.3/32  (csr-pe01)
└── 10.0.0.4/32  (csr-pe02)
```

### Underlay P-to-P Links (automatically configured by IS-IS)

```
10.1.0.0/24 — P-to-P core links
├── xrd01:Gi0-0-0-0 → 10.1.0.1/24
└── xrd02:Gi0-0-0-0 → 10.1.0.2/24

10.2.0.0/24 — P-to-PE uplinks
├── xrd01:Gi0-0-0-1 → 10.2.0.1/24
├── csr-pe01:eth1 → 10.2.0.3/24
├── xrd02:Gi0-0-0-1 → 10.2.0.2/24
└── csr-pe02:eth1 → 10.2.0.4/24
```

### Customer VRFs (Provisioned by Ansible)

**CustomerA (CUST_A):**
```
192.168.100.0/24 (via csr-pe01)
├── csr-pe01:GigabitEthernet3 → 192.168.100.1/24
├── n9k-ce01:Vlan100 → 192.168.100.2/24
└── linux-client1 → 192.168.100.10/32

192.168.200.0/24 (via csr-pe02)
├── csr-pe02:GigabitEthernet3 → 192.168.200.1/24
├── n9k-ce02:Vlan100 → 192.168.200.2/24
└── linux-client2 → 192.168.200.10/32
```

**CustomerB (CUST_B) — Optional:**
```
10.100.1.0/24 (via csr-pe01)
10.100.2.0/24 (via csr-pe02)
```

---

## Service Definitions

Services are defined in YAML (source of truth) and provisioned via Ansible playbooks.

### L3VPN Service

```yaml
# services/l3vpn/vars/customer_a.yml
customer: CustomerA
vrf: CUST_A
rd: "65000:100"
rt_export: "65000:100"
rt_import: "65000:100"
```

**Deployment:**
```bash
ansible-playbook ansible/playbooks/deploy_l3vpn.yml -i ansible/inventory/hosts.yml
```

### EVPN/VXLAN Service (Optional)

```yaml
# services/evpn/vars/vxlan_tenant.yml  
tenant: Tenant1
vlan_id: 1000
vni: 100100
```

---

## Boot Sequence & Readiness Check

After `containerlab deploy`, devices boot asynchronously. Monitor booting with:

```bash
# Watch all nodes
watch 'sudo containerlab inspect | tail -15'

# XRd (IOS-XR) — Usually ready in 45-60 seconds
ssh clab@172.20.20.10
xrd01# show version

# CSR (IOS-XE) — Usually ready in 30-45 seconds  
ssh admin@172.20.20.20
csr-pe01# show version

# N9Kv (NX-OS) — Usually ready in 3-5 minutes (slowest)
ssh admin@172.20.20.30
n9k-ce01# show version

# Linux — Immediately ready for SSH
ssh root@172.20.20.40
```

**All devices ready when:** `sudo containerlab inspect` shows `running` status for all 10 nodes and SSH is responsive.

---

## Configuration Files

Startup configs are stored in [../configs/](../configs/) and loaded by containerlab during `deploy`.

| File | Node | Purpose |
|------|------|---------|
| `xrd01.cfg` | xrd01 | IS-IS, LDP, BGP RR, loopback |
| `xrd02.cfg` | xrd02 | IS-IS, LDP, BGP RR, loopback |
| `csr-pe01.cfg` | csr-pe01 | IS-IS, LDP, BGP VPNv4 neighbor, loopback |
| `csr-pe02.cfg` | csr-pe02 | IS-IS, LDP, BGP VPNv4 neighbor, loopback |
| `n9k-ce01.cfg` | n9k-ce01 | OSPF, loopback |
| `n9k-ce02.cfg` | n9k-ce02 | OSPF, loopback |

These configs define the **underlay** (IS-IS, LDP, management). The **overlay** (VRFs, EVPN) is provisioned by Ansible playbooks.

---

## Validation Commands

Quick health checks:

```bash
# From lab host
sudo containerlab inspect

# Inside xrd01 (P/RR)
show bgp vpnv4 unicast summary

# Inside csr-pe01 (PE)
show vrf
show bgp vpnv4 unicast all neighbors | include Neighbor

# Inside n9k-ce01 (CE)
show bgp summary

# From linux-client1
ssh root@172.20.20.40
ping 192.168.100.1        # Should reach csr-pe01 across VLAN/VRF
traceroute 192.168.200.1  # Should go via L3VPN tunnel
```

---

## Resource Usage

Typical lab resource consumption (after 60 seconds of uptime):

| Resource | Usage |
|----------|-------|
| **CPU (8 cores)** | 35-45% |
| **Memory (32 GB)** | 6-8 GB |
| **Disk (per container)** | 300-500 MB |
| **Network (172.20.20.0/24)** | ~50 kbps (idle) |

For 30 parallel instances, scale proportionally: requires 16-core CPU + 64 GB+ RAM + 2 TB disk.

