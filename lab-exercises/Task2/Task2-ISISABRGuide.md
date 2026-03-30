# TASK 2: IS-IS with Area Border Router (ABR) Design - Complete Student Guide

**Duration:** 60 minutes  
**Level:** Intermediate  
**Devices:** CSR-PE01, CSR-PE02, N9K-CE01, N9K-CE02 (plus XRd backbone already running IS-IS)  
**Goal:** Enable RED clients (23.23.23.x) to reach CSR-PE01 loopback (192.168.10.11) and PURPLE clients (34.34.34.x) to reach CSR-PE02 loopback (192.168.10.12) via IS-IS routing  

---

## 📋 Table of Contents

1. [Learning Objectives](#learning-objectives)
2. [Concepts Overview](#concepts-overview)
3. [Topology Review](#topology-review)
4. [Current State vs. Target State](#current-state-vs-target-state)
5. [Architecture Decision: Why ABR?](#architecture-decision-why-abr)
6. [Lab Requirements](#lab-requirements)
7. [Step-by-Step Instructions](#step-by-step-instructions)
8. [Running the Playbook](#running-the-playbook)
9. [Validation](#validation)
10. [Expected Output](#expected-output)
11. [Troubleshooting](#troubleshooting)
12. [Playbook Walkthrough](#playbook-walkthrough)

---

## 🎯 Learning Objectives

By the end of Task 2, you will understand:

- **What is IS-IS?** A dynamic routing protocol that discovers network topology and calculates shortest paths
- **What is an area?** A logical grouping of routers in IS-IS that limits routing advertisements
- **What is an Area Border Router (ABR)?** A router that connects multiple IS-IS areas
- **Why use ABRs?** To isolate routing domains (important for customer separation in Task 3)
- **How do clients reach loopbacks?** Clients → N9K gateway → IS-IS learned route → CSR loopback
- **How to configure IS-IS on multiple devices** Using Ansible templates for consistency
- **How to validate routing** Using show commands and ping tests

---

## 📚 Concepts Overview

### Layer 3 Routing Recap

| Aspect | Description |
|--------|-------------|
| **Layer 3** | IP routing - sends packets based on IP address |
| **IGP** | Interior Gateway Protocol (e.g., IS-IS, OSPF, RIP) |
| **Dynamic Routing** | Router protocol discovers neighbors and calculates routes automatically |
| **Route Redistribution** | Sharing routes between different routing protocols |

**For Task 2:** We're adding IS-IS (an IGP) to enable client traffic to reach CSR loopbacks discovered dynamically.

---

### What is IS-IS (Intermediate System to Intermediate System)?

IS-IS is a **dynamic routing protocol** similar to OSPF:

| Aspect | IS-IS | OSPF |
|--------|-------|------|
| **Full Name** | Intermediate System to Intermediate System | Open Shortest Path First |
| **Standard** | ISO/IEC 10589 | RFC 2328+ |
| **Area Model** | Hierarchical (L1 = local, L2 = backbone) | Flat + Areas (OSPF areas separate, IS-IS hierarchical) |
| **Metric** | Configurable (default 10) | Cost (default based on bandwidth) |
| **Convergence** | Very fast (sub-second) | Fast (few seconds) |
| **Scalability** | Better for very large networks | Good for mid-sized networks |
| **Used by** | ISPs, service providers (common in core networks) | Enterprise networks |

**Why IS-IS for this lab?**
- Hierarchical area design (L1 for customers, L2 for backbone)
- Fast convergence
- Good for demonstrating ABR concepts that lead into Task 3 PE/CE architecture

---

### IS-IS Hierarchy: Level 1 vs Level 2

IS-IS has **two levels** of hierarchy:

```
┌─────────────────────────────────────────────────────────┐
│                   LEVEL 2 (Backbone)                    │
│                                                         │
│   XRd01 ─────────────────────────── XRd02             │
│    │                                  │                 │
│    │ (L2 IS-IS)                       │ (L2 IS-IS)     │
│    │                                  │                 │
│  CSR-PE01 (ABR)                    CSR-PE02 (ABR)     │
│    │                                  │                 │
│    │ L1 ↓ (area boundary)             │ L1 ↓           │
└────┼──────────────────────────────────┼─────────────────┘
     │                                  │
     │ (L1 IS-IS)                       │ (L1 IS-IS)
     │                                  │
   LEVEL 1 (Local domains)           LEVEL 1 (Local domains)
     │                                  │
   N9K-CE01                          N9K-CE02
     │                                  │
   Clients                           Clients
  23.23.23.x                        34.34.34.x
```

**Level 2 (L2):**
- Routers: XRd01, XRd02, CSR-PE01, CSR-PE02 (all connected)
- Purpose: Inter-area backbone routing
- Area ID: 49.0000.SP (Service Provider core)

**Level 1 (L1):**
- Routers: CSR-PE01/N9K-CE01 (RED) and CSR-PE02/N9K-CE02 (PURPLE)
- Purpose: Intra-area routing within isolated domains
- Area IDs: 49.0000.RED and 49.0000.PURPLE (isolated per customer)

**ABR (Area Border Router):**
- Is CPR-PE01 and CSR-PE02 (they connect L2 backbone to L1 local areas)
- Ability to participate in BOTH levels simultaneously
- They learn L2 routes from backbone and advertise key routes into L1 local domains

---

### Why ABR Design Matters for Task 2→3 Progression

| Aspect | Task 2 (Current) | Task 3 (Next) | Benefit |
|--------|------------------|---------------|---------|
| **Routing** | IS-IS in areas | BGP + VRF on top of IS-IS | Hierarchical then adds customer separation |
| **PE Function** | Route redistribution | BGP advertisement + VRF | CSRs stay ABRs, add services |
| **CE Function** | Dynamic routes | Still dynamic (N9K CE concepts) | Foundation for PE/CE service design |
| **Isolation** | Area boundaries | VRF + area boundaries | Defense-in-depth |

**In Task 3**, we'll add:
- BGP between CSRs (PEs) and XRds (P² backbone)
- VRF CUSTOMER_RED/PURPLE to isolate customer traffic
- L3VPN service model

So Task 2's ABR design is the **foundation** that makes Task 3's PE/CE and VRF design cleaner.

---

## 🔗 Topology Review

### Current State (End of Task 1)

```
RED CLIENTS                 ORANGE (CE)            GREEN (PE)        BLUE (Core)
client1 (23.23.23.1)   ─ eth1 ┐
client2 (23.23.23.2)   ─ eth1 ├─ N9K-CE01 ──── Gi4 ── CSR-PE01     XRd01
                              │   (L2 switch)       (No routing)      (IS-IS)
                              │   VLAN 10
                              │ eth1/3, eth1/4 ← 

PURPLE CLIENTS               (No routing yet)
client3 (34.34.34.1)   ─ eth1 ┐
client4 (34.34.34.2)   ─ eth1 ├─ N9K-CE02 ──── Gi4 ── CSR-PE02     XRd02
                              │   (L2 switch)       (No routing)      (IS-IS)
                              │   VLAN 20
                              │ eth1/3, eth1/4 ←

LEGEND:
[GREEN] = CSR (PE routers) — will add IS-IS
[ORANGE] = N9K (CE switches) — will add IS-IS
[BLUE] = XRd (core P routers) — already has IS-IS
[RED] = Clients — will stay L2/static defaults
```

### Target State (After Task 2)

```
RED CLIENTS                 ORANGE (CE)            GREEN (PE)        BLUE (Core)
client1 (23.23.23.1)   ─ eth1 ┐
client2 (23.23.23.2)   ─ eth1 ├─ N9K-CE01 ──── Gi4 ── CSR-PE01     XRd01
                              │   (IS-IS)        (IS-IS)          (IS-IS)
                              │   VLAN 10        ↓                ↓
                              │ eth1/3, eth1/4   router isis      router isis
                              │ (L2 only)        CUSTOMER_RED     CORE

PURPLE CLIENTS               ↑                   ↑
client3 (34.34.34.1)   ─ eth1 ┐                About IS-IS instances (two per CSR)
client4 (34.34.34.2)   ─ eth1 ├─ N9K-CE02 ──── Gi4 ── CSR-PE02     XRd02
                              │   (IS-IS)        (IS-IS)          (IS-IS)
                              │   VLAN 20        ↓                ↓
                              │ eth1/3, eth1/4   router isis      router isis
                              │ (L2 only)        CUSTOMER_PURPLE  CORE

LEGEND:
[GREEN] = CSR (PE routers) — ADD IS-IS
[ORANGE] = N9K (CE switches) — ADD IS-IS
[BLUE] = XRd (core P routers) — already has IS-IS
[RED] = Clients — UNCHANGED (still L2)
```

### Key Interface Mappings

| Device | Interface | Connected To | Used For | Status in Task 2 |
|--------|-----------|--------------|----------|------------------|
| CSR-PE01 | Gi2 | XRd01 (Gi0-0-0-1) | CORE IS-IS L2 | ADD IS-IS CORE |
| CSR-PE01 | Gi4 | N9K-CE01 (Eth1/1) | CUSTOMER_RED IS-IS L1 | ADD IS-IS CUSTOMER_RED |
| CSR-PE02 | Gi2 | XRd02 (Gi0-0-0-2) | CORE IS-IS L2 | ADD IS-IS CORE |
| CSR-PE02 | Gi4 | N9K-CE02 (Eth1/1) | CUSTOMER_PURPLE IS-IS L1 | ADD IS-IS CUSTOMER_PURPLE |
| N9K-CE01 | Eth1/1 | CSR-PE01 (Gi4) | CUSTOMER_RED IS-IS L1 | ADD IS-IS |
| N9K-CE01 | Eth1/3, Eth1/4 | Clients | L2 VLAN 10 | UNCHANGED |
| N9K-CE02 | Eth1/1 | CSR-PE02 (Gi4) | CUSTOMER_PURPLE IS-IS L1 | ADD IS-IS |
| N9K-CE02 | Eth1/3, Eth1/4 | Clients | L2 VLAN 20 | UNCHANGED |

---

## 🎲 Current State vs. Target State

### Current Packet Flow (Task 1 - L2 only)

**RED Client1 → RED Client2 (same VLAN):**
```
Client1 (23.23.23.1)
  ↓
  [ARP: who is 23.23.23.2?]
  ↓
  Ethernet frame to Client2 MAC
  ↓
  N9K-CE01 receives frame (VLAN 10)
  ↓  
  N9K forwards to Client2 via Ethernet [L2 forwarding]
  ↓
  Client2 (23.23.23.2)
  ✓ SUCCESS (L2 switching)
```

**RED Client1 → CSR-PE01 Loopback (192.168.10.11) - FAILS NOW:**
```
Client1 (23.23.23.1)
  ↓
  [ARP: who is 192.168.10.11?] → NO RESPONSE (wrong subnet!)
  ↓
  Default route: send to N9K gateway (23.23.23.254)
  ↓
  N9K-CE01 receives packet
  ↓
  [Lookup destination 192.168.10.11]
  ↗ NO ROUTE FOUND ❌
  ✗ FAILURE (no routing protocol)
```

### Target Packet Flow (Task 2 - L3 routing)

**RED Client1 → CSR-PE01 Loopback (192.168.10.11) - SUCCEEDS:**
```
Client1 (23.23.23.1)
  ↓
  [Check route to 192.168.10.11]
  ↓
  [Default route: send to N9K gateway (23.23.23.254)]
  ↓
  N9K-CE01 receives packet
  ↓
  [Lookup destination 192.168.10.11]
  ↓
  [IS-IS learned: 192.168.10.11/32 via CSR-PE01 192.168.10.11]
  ↓
  Forward to CSR-PE01 Gi4 (192.168.10.1)
  ↓
  CSR-PE01 receives packet on Gi4
  ↓
  [Lookup destination 192.168.10.11 = my Loopback0]
  ↓
  Receive packet locally
  ✓ SUCCESS (L3 IS-IS routing)
```

---

## ⚙️ Architecture Decision: Why ABR?

### Option A: Single Flat IS-IS Area (Simpler but Less Scalable)

**All devices in one area (49.0000.SP):**

```
All routers (XRd01, XRd02, CSR-PE01, CSR-PE02, N9K-CE01, N9K-CE02)
  in Area: 49.0000.SP
  
Result:
  ✓ Simpler configuration
  ✓ Faster deployment
  ✗ No isolation between RED and PURPLE customers
  ✗ RED clients can reach PURPLE infrastructure (security issue)
  ✗ No foundation for Task 3's VRF design
```

### Option B: ABR Design (Recommended - What We're Doing)

**Multiple areas with ABRs:**

```
[CORE Area: 49.0000.SP] ← XRd01, XRd02, and CSR-PE01/02 as L2 routers
     ↓
[CUSTOMER_RED Area: 49.0000.RED] ← CSR-PE01 (ABR) + N9K-CE01
[CUSTOMER_PURPLE Area: 49.0000.PURPLE] ← CSR-PE02 (ABR) + N9K-CE02

Result:
  ✓ Isolated customer routing domains
  ✓ RED clients CANNOT reach PURPLE infrastructure (security)
  ✓ CSRs act as ABRs (progression to PE/CE concept in Task 3)
  ✓ Foundation for VRF separation in Task 3
  ✓ Scales to many customers (one area per customer)
```

### Why ABR Design Prepares for Task 3

In **Task 3**, we'll add:
- BGP between CSRs (acting as PEs)
- VRF on top of IS-IS (customer traffic isolation)
- L3VPN service model

By using ABR areas in Task 2, we're already:
- Positioning CSRs as **service gateways** (PE role)
- Isolating **customer routing domains** (foundation for VRFs)
- Preparing **hierarchical design** (backbone + customer networks)

---

## 📌 Lab Requirements

**Before starting Task 2, verify:**

- [ ] Task 1 complete (clients have IPs, VLANs configured)
- [ ] You can SSH to CSRs (172.20.20.20, 172.20.20.21)
- [ ] You can SSH to N9Ks (internal or console access)
- [ ] Ansible is working: `ansible --version`
- [ ] Inventory file is populated with correct device IPs
- [ ] XRd IS-IS already running (`show isis neighbors` on XRds should show each other)

---

## 🚀 Step-by-Step Instructions

### STEP 1: Understand IS-IS Areas (10 minutes - LEARNING)

**What is an IS-IS area?**

Think of an IS-IS area like a office building:
- Level 2 routers are like the **building network** (all connected)
- Level 1 areas are like **office floors** (isolated, connected via building network)
- ABRs are like **building main junctions** (connect floors to building network)

**In Task 2 specifics:**

```
┌─────────────────────────────┐
│   CORE Area (L2 Backbone)   │  
│                             │
│  Routers:                   │
│  - XRd01, XRd02 (P routers) │
│  - CSR-PE01, CSR-PE02 (ABRs) │
│                             │
│  Area ID: 49.0000.SP        │
│  Type: Level 2-only         │
└─────────────────────────────┘
      ↓ ABRs distribute summaries ↓
     ①                              ②
┌──────────────────────┐   ┌──────────────────────┐
│ CUSTOMER_RED Area(L1)│   │ CUSTOMER_PURPLE(L1) │
│                      │   │                      │
│ Routers:             │   │ Routers:             │
│ - CSR-PE01 (ABR)     │   │ - CSR-PE02 (ABR)     │
│ - N9K-CE01 (L1)      │   │ - N9K-CE02 (L1)      │
│                      │   │                      │
│ Area IDs:            │   │ Area IDs:            │
│ 49.0000.RED.*        │   │ 49.0000.PURPLE.*     │
│ Type: Level 1-only   │   │ Type: Level 1-only   │
└──────────────────────┘   └──────────────────────┘
```

**Why this design?**
- XRds and CSRs all need to know about each other (Level 2)
- RED and PURPLE customers should NOT know about each other (separate Level 1 areas)
- CSRs bridge the gap (ABR role)

---

### STEP 2: Verify Current State (5 minutes)

**Task 1A: Check if IS-IS already exists**

```bash
# SSH to CSR-PE01
ssh admin@172.20.20.20

# Check if IS-IS is running
show run | include router isis
# Expected output: BLANK (no IS-IS configured yet)

# Check Gi2 (to XRd)
show int Gi2
# Expected:
# Interface GigabitEthernet2
# IP address 10.0.1.2 255.255.255.252
# Description TO_xrd01_Gi0-0-0-1
```

**Task 1B: Check XRds have IS-IS**

```bash
# SSH to XRd01
ssh clab@172.20.20.6  # (or your XRd access)

# Check IS-IS
show isis neighbors
# Expected output: Shows XRd02 as neighbor
```

**Task 1C: Check N9K is L2 only**

```bash
# SSH to N9K-CE01
# Check for routing protocols
show run | include router
# Expected output: BLANK (no router configs)

# Verify interfaces
show int br | i Eth1
# Expected:
# Eth1/1 — up (to CSR-PE01, not yet IS-IS)
# Eth1/3 — up (to client, VLAN 10)
# Eth1/4 — up (to client, VLAN 10)
```

---

### STEP 3-A: Configure CSR-PE01 as ABR (15 minutes)

**Goal:** Configure CSR-PE01 to run TWO IS-IS instances:
1. **CORE** area (L2) — connects Gi2 to XRd01
2. **CUSTOMER_RED** area (L1) — connects Gi4 to N9K-CE01

**Manual Configuration (if not using Ansible):**

```cisco
csr-pe01# configure terminal

! ===== ENABLE FIRST IS-IS INSTANCE: CORE =====
csr-pe01(config)# router isis CORE
csr-pe01(config-router)# net 49.0000.00000000.0011.00
csr-pe01(config-router)# is-type level-2-only
csr-pe01(config-router)# metric-style wide
csr-pe01(config-router)# passive-interface Loopback0
csr-pe01(config-router)# exit

! ===== ENABLE SECOND IS-IS INSTANCE: CUSTOMER_RED =====
csr-pe01(config)# router isis CUSTOMER_RED
csr-pe01(config-router)# net 49.0000.RED.csrpe01.00
csr-pe01(config-router)# is-type level-1-only
csr-pe01(config-router)# metric-style wide
csr-pe01(config-router)# passive-interface Loopback0
csr-pe01(config-router)# exit

! ===== ENABLE IS-IS ON Gi2 (CORE area, Level 2) =====
csr-pe01(config)# interface GigabitEthernet2
csr-pe01(config-if)# ip router isis CORE
csr-pe01(config-if)# isis circuit-type level-2-only
csr-pe01(config-if)# exit

! ===== ENABLE IS-IS ON Gi4 (CUSTOMER_RED area, Level 1) =====
csr-pe01(config)# interface GigabitEthernet4
csr-pe01(config-if)# ip router isis CUSTOMER_RED
csr-pe01(config-if)# isis circuit-type level-1
csr-pe01(config-if)# exit

! ===== ENABLE IS-IS ON Loopback0 (BOTH instances) =====
csr-pe01(config)# interface Loopback0
csr-pe01(config-if)# ip router isis CORE
csr-pe01(config-if)# ip router isis CUSTOMER_RED
csr-pe01(config-if)# exit

csr-pe01(config)# exit
csr-pe01# write memory
```

**Verification after manual config:**

```bash
show isis summary
# Shows: ISIS routing is enabled
#        Instance CORE: L2
#        Instance CUSTOMER_RED: L1

show isis neighbors
# Shows: Connections to XRd01 (via Gi2)  [CORE L2]
#        Connections to N9K-CE01 (via Gi4) [CUSTOMER_RED L1] (once N9K is configured)
```

---

### STEP 3-B: Configure CSR-PE02 as ABR (Mirror of Step 3-A)

**Goal:** Configure CSR-PE02 to run TWO IS-IS instances:
1. **CORE** area (L2) — connects Gi2 to XRd02
2. **CUSTOMER_PURPLE** area (L1) — connects Gi4 to N9K-CE02

**Manual Configuration:**

```cisco
csr-pe02# configure terminal

! ===== ENABLE FIRST IS-IS INSTANCE: CORE =====
csr-pe02(config)# router isis CORE
csr-pe02(config-router)# net 49.0000.00000000.0012.00
csr-pe02(config-router)# is-type level-2-only
csr-pe02(config-router)# metric-style wide
csr-pe02(config-router)# passive-interface Loopback0
csr-pe02(config-router)# exit

! ===== ENABLE SECOND IS-IS INSTANCE: CUSTOMER_PURPLE =====
csr-pe02(config)# router isis CUSTOMER_PURPLE
csr-pe02(config-router)# net 49.0000.PURPLE.csrpe02.00
csr-pe02(config-router)# is-type level-1-only
csr-pe02(config-router)# metric-style wide
csr-pe02(config-router)# passive-interface Loopback0
csr-pe02(config-router)# exit

! ===== ENABLE IS-IS ON Gi2 (CORE area, Level 2) =====
csr-pe02(config)# interface GigabitEthernet2
csr-pe02(config-if)# ip router isis CORE
csr-pe02(config-if)# isis circuit-type level-2-only
csr-pe02(config-if)# exit

! ===== ENABLE IS-IS ON Gi4 (CUSTOMER_PURPLE area, Level 1) =====
csr-pe02(config)# interface GigabitEthernet4
csr-pe02(config-if)# ip router isis CUSTOMER_PURPLE
csr-pe02(config-if)# isis circuit-type level-1
csr-pe02(config-if)# exit

! ===== ENABLE IS-IS ON Loopback0 (BOTH instances) =====
csr-pe02(config)# interface Loopback0
csr-pe02(config-if)# ip router isis CORE
csr-pe02(config-if)# ip router isis CUSTOMER_PURPLE
csr-pe02(config-if)# exit

csr-pe02(config)# exit
csr-pe02# write memory
```

---

### STEP 4: Configure N9K-CE01 with IS-IS (10 minutes)

**Goal:** Configure N9K-CE01 to peer with CSR-PE01 in CUSTOMER_RED area

**Manual Configuration:**

```cisco
n9k-ce01# configure terminal

! ===== ENABLE IS-IS INSTANCE: CUSTOMER_RED =====
n9k-ce01(config)# router isis CUSTOMER_RED
n9k-ce01(config-router)# net 49.0000.RED.n9kce01.00
n9k-ce01(config-router)# is-type level-1-only
n9k-ce01(config-router)# metric-style wide
n9k-ce01(config-router)# exit

! ===== ENABLE IS-IS ON Eth1/1 (to CSR-PE01, Level 1) =====
n9k-ce01(config)# interface Ethernet1/1
n9k-ce01(config-if)# description TO_CSR_PE01
n9k-ce01(config-if)# ip router isis CUSTOMER_RED
n9k-ce01(config-if)# isis circuit-type level-1
n9k-ce01(config-if)# exit

! ===== ENABLE IS-IS ON Loopback0 =====
n9k-ce01(config)# interface loopback0
n9k-ce01(config-if)# ip router isis CUSTOMER_RED
n9k-ce01(config-if)# isis passive
n9k-ce01(config-if)# exit

! ===== REDISTRIBUTE CONNECTED ROUTES (client subnets) =====
n9k-ce01(config)# route-map ALLOW_ALL permit 10
n9k-ce01(config-route-map)# exit

n9k-ce01(config)# router isis CUSTOMER_RED
n9k-ce01(config-router)# redistribute connected route-map ALLOW_ALL
n9k-ce01(config-router)# exit

n9k-ce01(config)# exit
n9k-ce01# copy running-config startup-config
```

**Why redistribute connected?**
- Client VLAN 10 (23.23.23.0/24) is "connected" on N9K-CE01
- By redistributing, N9K advertises this subnet into IS-IS
- CSR-PE01 learns: "Network 23.23.23.0/24 is 1 hop away via N9K"
- This is important for **reverse traffic** (CSR needs to know how to reach clients)

---

### STEP 5: Configure N9K-CE02 with IS-IS (Mirror of Step 4)

**Goal:** Configure N9K-CE02 to peer with CSR-PE02 in CUSTOMER_PURPLE area

**Manual Configuration:**

```cisco
n9k-ce02# configure terminal

! ===== ENABLE IS-IS INSTANCE: CUSTOMER_PURPLE =====
n9k-ce02(config)# router isis CUSTOMER_PURPLE
n9k-ce02(config-router)# net 49.0000.PURPLE.n9kce02.00
n9k-ce02(config-router)# is-type level-1-only
n9k-ce02(config-router)# metric-style wide
n9k-ce02(config-router)# exit

! ===== ENABLE IS-IS ON Eth1/1 (to CSR-PE02, Level 1) =====
n9k-ce02(config)# interface Ethernet1/1
n9k-ce02(config-if)# description TO_CSR_PE02
n9k-ce02(config-if)# ip router isis CUSTOMER_PURPLE
n9k-ce02(config-if)# isis circuit-type level-1
n9k-ce02(config-if)# exit

! ===== ENABLE IS-IS ON Loopback0 =====
n9k-ce02(config)# interface loopback0
n9k-ce02(config-if)# ip router isis CUSTOMER_PURPLE
n9k-ce02(config-if)# isis passive
n9k-ce02(config-if)# exit

! ===== REDISTRIBUTE CONNECTED ROUTES (client subnets) =====
n9k-ce02(config)# route-map ALLOW_ALL permit 10
n9k-ce02(config-route-map)# exit

n9k-ce02(config)# router isis CUSTOMER_PURPLE
n9k-ce02(config-router)# redistribute connected route-map ALLOW_ALL
n9k-ce02(config-router)# exit

n9k-ce02(config)# exit
n9k-ce02# copy running-config startup-config
```

---

## 🏃 Running the Playbook

### Option 1: Run Complete Playbook (Recommended for learning)

```bash
cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises/Task2

# Run complete deployment
ansible-playbook -i inventory/hosts.yml playbooks/00_deploy_task2.yml -v

# With specific tags
ansible-playbook -i inventory/hosts.yml playbooks/00_deploy_task2.yml -t deploy,validate -v
```

### Option 2: Run Individual Playbooks

```bash
# Step 1: Deploy CSR configuration
ansible-playbook -i inventory/hosts.yml playbooks/01_deploy_isis_csr.yml -v

# Step 2: Deploy N9K configuration
ansible-playbook -i inventory/hosts.yml playbooks/02_deploy_isis_nxos.yml -v

# Step 3: Validate
ansible-playbook -i inventory/hosts.yml playbooks/03_validate_isis.yml -v
```

### Troubleshooting Playbook Issues

If authentication fails:

```bash
# Add credentials to inventory or environment
export ANSIBLE_NET_USERNAME=admin
export ANSIBLE_NET_PASSWORD=admin

# Or use -k flag
ansible-playbook -i inventory/hosts.yml playbooks/00_deploy_task2.yml -k -v
```

If SSH key issues:

```bash
# Use password auth instead
ansible-playbook -i inventory/hosts.yml playbooks/00_deploy_task2.yml -k --extra-vars="ansible_password=admin"
```

---

## ✅ Validation

### Validation 1: Check IS-IS Neighbors

**On CSR-PE01:**
```bash
show isis neighbors
# Expected output:
# System ID      Type Interface   IP Address      State Holdtime Circuit ID
# xrd01.00       L2   Gi2         10.0.1.1        UP    27       xrd01.00
# n9k-ce01.00    L1   Gi4         10.1.0.2        UP    27       n9k-ce01.00
```

**On N9K-CE01:**
```bash
show isis neighbors
# Expected output:
# System ID      Type Interface   IP Address      State Holdtime Circuit ID
# csr-pe01.00    L1   Eth1/1      10.1.0.1        UP    27       csr-pe01.00
```

**What this means:**
- CSR-PE01 has 2 neighbors (XRd01 as L2, N9K-CE01 as L1)
- N9K-CE01 has 1 neighbor (CSR-PE01 as L1)
- This is **CORRECT** (ABR design with different levels)

---

### Validation 2: Check IS-IS Database

**On CSR-PE01:**
```bash
show isis database
# Shows:
# Level-2 database (CORE area):
# - XRd01, XRd02, CSR-PE01, CSR-PE02 (all L2 routers)
# 
# Level-1 database (CUSTOMER_RED area):
# - CSR-PE01, N9K-CE01
```

---

### Validation 3: Check Routing Table

**On CSR-PE01:**
```bash
show ip route isis
# Expected routes:
# i    192.168.10.12/32 [115/20] via 172.20.20.0 (via XRd backbone to CSR-PE02)
# i    192.168.10.6/32 [115/10] via 172.20.20.0 (via XRd01)
# i    192.168.10.7/32 [115/10] via 172.20.20.0 (via XRd02)
# i L1 23.23.23.0/24 [115/20] via 10.1.0.2 (N9K-CE01 - connected route redistribution)
```

**On N9K-CE01:**
```bash
show ip route isis
# Expected routes:
# i L1 192.168.10.11/32 [115/10] via 10.1.0.1 (CSR-PE01 loopback)
# (Other redistributed routes from CSR-PE01)
```

---

### Validation 4: Ping Test - Clients to Loopbacks

**From RED client (23.23.23.1):**
```bash
# On linux-client1
ping -c 4 192.168.10.11
# Expected output:
# PING 192.168.10.11 (192.168.10.11): 56 data bytes
# 64 bytes from 192.168.10.11: icmp_seq=0 ttl=63 time=X ms
# 64 bytes from 192.168.10.11: icmp_seq=1 ttl=63 time=X ms
# 64 bytes from 192.168.10.11: icmp_seq=2 ttl=63 time=X ms
# 64 bytes from 192.168.10.11: icmp_seq=3 ttl=63 time=X ms
# --- 192.168.10.11 statistics ---
# 4 packets transmitted, 4 packets received, 0% packet loss
```

**What this means:**
- ✓ Client 1 can reach CSR-PE01 loopback
- ✓ Routing path works: Client → N9K → CSR
- ✓ Red clients have connectivity

---

### Validation 5: Ping Test - RED Clients NOT Reaching PURPLE Target

**From RED client (23.23.23.1):**
```bash
ping -c 4 192.168.10.12
# Expected output:
# PING 192.168.10.12 (192.168.10.12): 56 data bytes
# (NO REPLY - timeout after 4-5 seconds)
# --- 192.168.10.12 statistics ---
# 4 packets transmitted, 0 packets received, 100% packet loss
```

**What this means:**
- ✓ RED clients CANNOT reach CSR-PE02 loopback
- ✓ Area isolation working (RED area only knows RED routes)
- ✓ Security boundary enforced

**Why this is important:**
- In Task 3, this will become VRF isolation
- But already in Task 2, we have routing domain separation
- This demonstrates why ABR design matters

---

## 📊 Expected Output

### Sample CSR-PE01 Neighbor Table

```
csr-pe01#show isis neighbors

System ID      Type Interface   IP Address      State Holdtime Circuit ID
xrd01.00       L2   Gi2         10.0.1.1        UP    24       xrd01.00
csr-pe02.00    L2   Gi2         10.0.1.1        UP    26       csr-pe02.00
n9k-ce01.00    L1   Gi4         10.1.0.2        UP    23       n9k-ce01.00

Total: 3 neighbors
```

### Sample N9K-CE01 Neighbor Table

```
n9k-ce01# show isis neighbors

System ID      Type Interface   IP Address      State Holdtime Circuit ID
csr-pe01.00    L1   Eth1/1      10.1.0.1        UP    27       csr-pe01.00

Total: 1 neighbor
```

### Sample CSR-PE01 IS-IS Database

```
csr-ce01#show isis database

Level-2 Link State Database:
LSPID                 Seq   Checksum  Lifetime  Attributes
xrd01.00-00           *      28593     1102      L2
xrd02.00-00           *      28593     1102      L2
csr-pe01.00-00        *      28593     1102      L2
csr-pe02.00-00        *      28593     1102      L2

Level-1 Link State Database:
LSPID                 Seq   Checksum  Lifetime  Attributes
csr-pe01.00-00        *      28593     1102      L1
n9k-ce01.00-00        *      28593     1102      L1
```

---

## 🔧 Troubleshooting

### Issue 1: IS-IS Neighbors Not Showing Up

**Problem:**
```bash
csr-pe01#show isis neighbors
# Output: (empty - no neighbors)
```

**Causes and Solutions:**

| Symptom | Cause | Solution |
|---------|-------|----------|
| No neighbors at all | IS-IS not enabled on interfaces | Verify `show run` shows `ip router isis` on Gi2/Gi4 |
| XRd neighbor missing | Gi2 not configured as L2 | Add `isis circuit-type level-2-only` to Gi2 |
| N9K neighbor missing | Gi4 not configured as L1 | Add `isis circuit-type level-1` to Gi4 |
| Link flapping | Interface MTU mismatch | Verify all interfaces have MTU 1500+ |
| Down state | Area NET mismatch | Verify CSR-PE01/CSR-PE02 are in same CORE area (49.0000.SP) |
| L1 not showing | N9K not running IS-IS | Run Steps 4-5 to configure N9Ks |

**Debugging Steps:**

1. **Check interface IS-IS status:**
```bash
show isis interface brief
# Should show Gi2 (L2 area) and Gi4 (L1 area)
```

2. **Check if interface is up:**
```bash
show int Gi2 | include up
show int Gi4 | include up
# Both should show "up up"
```

3. **Check for IS-IS errors:**
```bash
show isis statistics
# Look for any error counters
```

4. **Enable debug (if needed):**
```bash
debug isis adj-packets      # See adjacency forming
undebug all                  # Turn off debugging
```

---

### Issue 2: Clients Cannot Ping Loopbacks

**Problem:**
```bash
linux-client1:~$ ping 192.168.10.11
connect: Network is unreachable
```

**Causes and Solutions:**

| Symptom | Cause | Solution |
|---------|-------|----------|
| Network unreachable | N9K doesn't have route to loopback | Verify N9K has IS-IS neighbor (Step 4) |
| TimeOut (no reply) | CSR loopback not in IS-IS | Verify Loopback0 has `ip router isis` |
| High latency (slow) | IS-ISIS not converged yet | Wait 30-60 seconds after config |
| Only some clients work | N9K not redistributing client subnets | Verify `redistribute connected` on N9Ks |

**Debugging Steps:**

1. **Check client's routing:**
```bash
# On linux-client1
route -n
# Should show:
# 0.0.0.0/0 via 23.23.23.254 (N9K gateway)
# and interface on eth1
```

2. **Traceroute to loopback:**
```bash
traceroute 192.168.10.11
# Should show: Client → N9K (hop 1) → CSR (hop 2)
```

3. **Check N9K routing:**
```bash
# SSH to N9K-CE01
show ip route | grep 192.168.10.11
# Should show IS-IS route
```

4. **Check CSR loopback:**
```bash
# SSH to CSR-PE01
show int Loopback0
# Should show:
# IP address 192.168.10.11 255.255.255.255
# is up, line protocol is up
```

---

### Issue 3: Red Clients CAN Reach Purple Loopback (Area Isolation Failed)

**Problem:**
```bash
linux-client1:~$ ping 192.168.10.12
64 bytes from 192.168.10.12: icmp_seq=0 ttl=62 time=X ms
# REPLY (this should NOT happen!)
```

**Causes:**

1. **CSRs didn't configure two separate IS-IS instances**
   - Verify both CORE and CUSTOMER_* instances exist
   - Show `router isis CORE` and `router isis CUSTOMER_RED/CUSTOMER_PURPLE`

2. **N9K configured with L2 instead of L1**
   - Verify `is-type level-1-only` on N9Ks
   - Should NOT have `level-2` participation

3. **Loopback0 added to both instances on CSRs (overlapping)**
   - This is OK - loopback is in both areas for ABR function
   - Issue is likely above

**Fix:**

1. Verify CSR-PE01 has BOTH routers:
```bash
show run | include router isis
# Should show:
# router isis CORE
# router isis CUSTOMER_RED
```

2. Verify L1 boundaries:
```bash
show isis neighbors
# Output should show:
# L2: xrd01, xrd02, csr-pe02 (CORE area)
# L1: n9k-ce01 (CUSTOMER_RED area)
```

---

## 📖 Playbook Walkthrough

### Master Playbook: 00_deploy_task2.yml

This playbook orchestrates the entire Task 2 deployment:

```yaml
- name: "Task 2: IS-IS with Area Border Router (ABR) Design"
  hosts: all

  pre_tasks:
    # Display header and architecture diagram
    - debug: msg: [Header showing goal and areas]
    
  tasks:
    # Include CSR tasks for devices starting with 'csr'
    - include_tasks: 01_deploy_isis_csr.yml
      when: inventory_hostname.startswith('csr')
    
    # Include N9K tasks for devices starting with 'n9k'
    - include_tasks: 02_deploy_isis_nxos.yml
      when: inventory_hostname.startswith('n9k')
  
  post_tasks:
    # Wait for convergence
    - pause: seconds: 30
    
    # Run validation
    - include_tasks: 03_validate_isis.yml
```

**Flow:**
1. Display learning header
2. Deploy CSR configs in parallel (both CSRs at same time)
3. Deploy N9K configs in parallel (both N9Ks at same time)
4. Wait 30 seconds
5. Validate with show commands
6. Display completion message

---

### CSR Playbook: 01_deploy_isis_csr.yml

This playbook configures CSRs as ABRs:

**Key Tasks:**

1. **Generate config from Jinja2 template**
   - Takes variables from inventory (isis_instances, interfaces)
   - Creates device-specific config

2. **Configure CORE IS-IS router**
   - Creates `router isis CORE` instance
   - Sets Level 2 (backbone)

3. **Configure CUSTOMER IS-IS router**
   - Creates `router isis CUSTOMER_RED/CUSTOMER_PURPLE`
   - Sets Level 1 (local area)

4. **Enable IS-IS on interfaces**
   - Gi2: Part of CORE area (L2)
   - Gi4: Part of CUSTOMER area (L1)
   - Loopback0: Part of both (ABR function)

5. **Save and verify**
   - Write memory (persist config)
   - Show IS-IS summary
   - Show IS-IS neighbors

---

### N9K Playbook: 02_deploy_isis_nxos.yml

This playbook configures N9Ks as CEs:

**Key Tasks:**

1. **Generate config from Jinja2 template**
   - Takes variables from inventory

2. **Configure CUSTOMER IS-IS router**
   - Creates `router isis CUSTOMER_RED/CUSTOMER_PURPLE`
   - Sets Level 1 only

3. **Enable IS-IS on interfaces**
   - Eth1/1: Connection to CSR (L1)
   - Loopback0: Router ID
   - Eth1/3, Eth1/4: NOT IS-IS (remain L2)

4. **Redistribute connected routes**
   - Creates route-map to allow all routes
   - Redistributes connected subnets (VLAN 10/20)

5. **Save and verify**
   - Copy running to startup
   - Show IS-IS summary
   - Show IS-IS neighbors

---

### Validation Playbook: 03_validate_isis.yml

This playbook verifies deployment:

**Key Validations:**

1. **Check neighbors on all devices**
   - CSRs should show both L2 and L1 neighbors
   - N9Ks should show only L1 neighbor (CSR)
   - XRds should see CSRs in L2 domain

2. **Check IS-IS database**
   - Verify Level-2 database includes all backbone routers
   - Verify Level-1 databases are separated per area

3. **Check routing tables**
   - CSRs should learn loopbacks via IS-IS
   - N9Ks should learn CSR loopbacks
   - Verify client subnets are redistributed

4. **Ping tests**
   - RED clients → CSR-PE01 loopback (should work)
   - PURPLE clients → CSR-PE02 loopback (should work)
   - RED clients → CSR-PE02 loopback (should NOT work)
   - PURPLE clients → CSR-PE01 loopback (should NOT work)

---

## 📝 Summary

**Task 2 Accomplishment:**

✅ **Configured IS-IS on all core devices**
- CSRs: CORE + CUSTOMER areas
- N9Ks: CUSTOMER areas
- XRds: Already had CORE area

✅ **Established Area Border Router (ABR) design**
- CSRs bridge CORE (backbone) and CUSTOMER areas
- N9Ks isolated in their respective CUSTOMER areas

✅ **Enabled client loopback reachability**
- RED clients can ping CSR-PE01 loopback
- PURPLE clients can ping CSR-PE02 loopback

✅ **Enforced area isolation**
- Customers cannot reach each other's infrastructure
- Foundation for Task 3 VRF model

---

## 🎯 Next Steps: Task 3

Task 3 will build on Task 2's ABR architecture by adding:

1. **BGP peering** between CSRs (PEs) and XRds (backbone P routers)
2. **VRF domains** for customer traffic isolation
3. **L3VPN service model** with customer RD/RT

The IS-IS ABR design in Task 2 creates the perfect foundation for these service provider concepts.

---

## 📚 Additional Resources

- [IS-IS RFC 10589](https://tools.ietf.org/html/rfc10589) (ISO standard)
- Cisco IS-IS documentation
- Ansible network playbook examples
- Service Provider routing design patterns

**End of Task 2 Guide**
