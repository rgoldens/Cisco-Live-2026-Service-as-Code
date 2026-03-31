# Task 3: SP Core — MPLS L3VPN with iBGP Route Reflectors

**Objective**: Build an MPLS L3VPN service across the SP core using ISIS as the IGP, LDP for label distribution, and iBGP VPNv4 with route reflectors.

## Topology Overview

```
Clients 1/2 (RED)          Clients 3/4 (PURPLE)
    |                           |
N9K-CE01                    N9K-CE02
 Eth1/1                     Eth1/1
    |                           |
  Gi4                         Gi4
 CSR-PE01                   CSR-PE02
  Gi2                         Gi2
    |                           |
 Gi0/0/0/1                  Gi0/0/0/1
  XRd01 ---- backbone ---- XRd02
       Gi0/0/0/0    Gi0/0/0/0
```

All devices are in **ASN 65000** (single iBGP domain).

## Device Roles

| Device | Role | ASN | Loopback0 | Key Links |
|--------|------|-----|-----------|-----------|
| XRd01 | P-Router / Route Reflector | 65000 | 192.168.0.1 | Gi0/0/0/0→xrd02, Gi0/0/0/1→csr-pe01 |
| XRd02 | P-Router / Route Reflector | 65000 | 192.168.0.2 | Gi0/0/0/0→xrd01, Gi0/0/0/1→csr-pe02 |
| CSR-PE01 | PE Router (RR client) | 65000 | 192.168.10.11 | Gi2→xrd01, Gi4→n9k-ce01 (VRF CUST_A) |
| CSR-PE02 | PE Router (RR client) | 65000 | 192.168.10.12 | Gi2→xrd02, Gi4→n9k-ce02 (VRF CUST_A) |

## Routing Design

### IGP: ISIS CORE (Level-2)
- **Pre-configured**: XRd backbone ISIS (Gi0/0/0/0 + Lo0)
- **Task 2 deployed**: CSR ISIS CORE on Gi2 + Lo0
- **Task 3 adds**: XRd Gi0/0/0/1 to ISIS CORE (P-PE links)

### MPLS: LDP
- XRd: LDP on Gi0/0/0/0 (backbone) + Gi0/0/0/1 (PE link), router-id = Loopback0
- CSR: LDP router-id Loopback0, `mpls ip` on Gi2

### BGP: iBGP VPNv4 (ASN 65000)
- XRd01/XRd02 = Route Reflectors
- CSR-PE01/PE02 = RR Clients, update-source Loopback0

### VPN: VRF CUST_A
- RD 65000:100, RT import/export 65000:100
- CSR Gi4 placed into VRF CUST_A (replaces Task 2's flat ISIS CUSTOMER)
- `redistribute connected` advertises CE-facing subnets into VPNv4

## Playbooks

### Run Sequence

```bash
# Prerequisites: Task 2 must be completed first (ISIS CORE on CSRs)

# Step 1: Deploy underlay (ISIS PE links + MPLS LDP)
ansible-playbook -i inventory/hosts.yml Task3/playbooks/01_deploy_underlay.yml -v

# Step 2: Deploy overlay (BGP VPNv4 + VRF CUST_A)
ansible-playbook -i inventory/hosts.yml Task3/playbooks/02_deploy_overlay.yml -v

# Step 3: Validate end-to-end
ansible-playbook -i inventory/hosts.yml Task3/playbooks/03_validate_task3.yml -v
```

### Playbook Details

1. **01_deploy_underlay.yml**
   - Adds XRd Gi0/0/0/1 to ISIS CORE (P-PE links join the backbone)
   - Configures MPLS LDP on XRd (all interfaces) and CSR (Gi2)
   - Validates ISIS neighbors and LDP sessions

2. **02_deploy_overlay.yml**
   - Configures BGP 65000 on XRd with VPNv4 address-family and route-reflector-client
   - Configures BGP 65000 on CSR with VPNv4, VRF CUST_A, update-source Lo0
   - Places CSR Gi4 into VRF CUST_A (note: this strips Task 2's ISIS CUSTOMER from Gi4)
   - Validates BGP VPNv4 sessions

3. **03_validate_task3.yml**
   - Checks ISIS adjacencies (XRd should see 2 neighbors each)
   - Checks MPLS LDP neighbors
   - Checks BGP VPNv4 summary (sessions should be Established)
   - Pings CSR PE loopbacks from XRd
   - Displays VRF routing table on CSRs

## Expected End State

After Task 3 completes successfully:
- ISIS: Full L2 mesh (xrd01↔xrd02, xrd01↔csr-pe01, xrd02↔csr-pe02)
- MPLS LDP: Label distribution across all core links
- BGP VPNv4: XRd RRs have Established sessions to both CSR PEs
- VRF CUST_A: CE-facing subnets (10.2.0.0/30, 10.2.0.4/30) in VPNv4 table
