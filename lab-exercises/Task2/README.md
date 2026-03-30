# Task 2: IS-IS with Area Border Router (ABR) Design

**Duration:** 60 minutes  
**Level:** Intermediate  
**Devices:** CSR-PE01, CSR-PE02, N9K-CE01, N9K-CE02, XRd01, XRd02 (via IS-IS)  
**Goal:** Enable RED and PURPLE clients to reach their respective CSR PE loopbacks via IS-IS routing

---

## 📌 Quick Start

### Prerequisites
- Task 1 complete (clients have IPs, VLANs configured)
- You can SSH to CSRs and N9Ks
- Ansible is available in lab environment

### Deploy Task 2

```bash
cd lab-exercises/Task2

# Run the master playbook
ansible-playbook -i inventory/hosts.yml playbooks/00_deploy_task2.yml

# Or run individually:
ansible-playbook -i inventory/hosts.yml playbooks/01_deploy_isis_csr.yml
ansible-playbook -i inventory/hosts.yml playbooks/02_deploy_isis_nxos.yml
ansible-playbook -i inventory/hosts.yml playbooks/03_validate_isis.yml
```

### Validate Results

**On RED clients (linux-client1, linux-client2):**
```bash
ping 192.168.10.11  # Should get REPLY
```

**On PURPLE clients (linux-client3, linux-client4):**
```bash
ping 192.168.10.12  # Should get REPLY
```

**On CSRs:**
```bash
show isis neighbors          # Verify adjacencies
show isis database           # Verify database
show ip route isis           # Verify learned routes
```

**On N9Ks:**
```bash
show isis neighbors          # Verify adjacencies
show isis database           # Verify database
show ip route isis           # Verify learned routes
```

---

## 📂 Directory Structure

```
Task2/
├── Task2-ISISABRGuide.md          ← Comprehensive student guide (NEXT)
├── README.md                      ← This file
├── docs/
│   ├── isis_concepts.md
│   ├── abr_design.md
│   └── troubleshooting.md
├── inventory/
│   ├── hosts.yml                  ← Device list
│   └── group_vars/
│       ├── csr/all.yml            ← CSR variables
│       ├── csr/csr-pe01.yml       ← CSR-PE01 specifics
│       ├── csr/csr-pe02.yml       ← CSR-PE02 specifics
│       ├── nxos/all.yml           ← N9K variables
│       ├── nxos/n9k-ce01.yml      ← N9K-CE01 specifics
│       └── nxos/n9k-ce02.yml      ← N9K-CE02 specifics
├── playbooks/
│   ├── 00_deploy_task2.yml        ← Master orchestration playbook
│   ├── 01_deploy_isis_csr.yml     ← Deploy CSR configuration
│   ├── 02_deploy_isis_nxos.yml    ← Deploy N9K configuration
│   └── 03_validate_isis.yml       ← Validation tests
└── roles/
    ├── csr_isis_abr/
    │   └── templates/
    │       └── isis_config.j2      ← CSR config template
    └── nxos_isis/
        └── templates/
            └── isis_config.j2      ← N9K config template
```

---

## 🎯 What You'll Learn

1. **IS-IS Routing Protocol**
   - How IS-IS discovers neighbors
   - IS-IS areas and hierarchies
   - Level 1 vs Level 2

2. **Area Border Routers (ABRs)**
   - Why ABRs important for network design
   - How ABRs connect multiple areas
   - Benefits: isolation, scalability, modularity

3. **Customer Network Segmentation**
   - Isolating customer routing domains
   - Why areas prevent cross-customer traffic
   - Preparation for Task 3's VRF model

4. **Ansible Network Automation**
   - Multi-device orchestration
   - Configuration templating
   - Validation and verification

---

## 📋 Learning Objectives

By the end of Task 2, you will:
- ✅ Understand IS-IS routing and area design
- ✅ Configure CSRs as Area Border Routers
- ✅ Deploy IS-IS to customer CEs (N9Ks)
- ✅ Verify loopback reachability for clients
- ✅ Validate area isolation and routing

---

## 🔄 Connection to Other Tasks

**Built on:** Task 1 (L2 VLAN connectivity, client IPs)  
**Used by:** Task 3 (Inter-AS Option A, BGP, L3VPN)

---

## 📖 Next: Read Task2-ISISABRGuide.md

This README is a quick reference. For comprehensive learning:

1. **Concepts:** Read docs/isis_concepts.md
2. **Architecture:** Read docs/abr_design.md
3. **Full Guide:** Read Task2-ISISABRGuide.md
4. **Troubleshooting:** Read docs/troubleshooting.md

---

## ❓ Questions?

Refer to the comprehensive guide: `Task2-ISISABRGuide.md`
