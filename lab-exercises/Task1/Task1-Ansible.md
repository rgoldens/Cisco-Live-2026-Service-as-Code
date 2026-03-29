# TASK 1: Ansible Reachability Service - Complete Student Guide

**Duration:** 45 minutes  
**Level:** Beginner  
**Devices:** n9k-ce01, n9k-ce02 (ORANGE switches)  
**Goal:** Enable RED clients and PURPLE clients to reach each other within their own groups  

---

## 📋 Table of Contents

1. [Learning Objectives](#learning-objectives)
2. [Concepts Overview](#concepts-overview)
3. [Topology Review](#topology-review)
4. [Lab Requirements](#lab-requirements)
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Running the Playbook](#running-the-playbook)
7. [Validation](#validation)
8. [Expected Output](#expected-output)
9. [Troubleshooting](#troubleshooting)
10. [Playbook Walkthrough](#playbook-walkthrough)

---

## 🎯 Learning Objectives

By the end of Task 1, you will understand:

- **What is Ansible?** An automation platform that uses YAML files to configure devices
- **What is an inventory?** A file that tells Ansible which devices exist and how to reach them
- **How do variables work?** Configuration values that can be reused across playbooks
- **What is Layer 2 switching?** How VLANs segment and forward frames
- **What is idempotency?** Why running a playbook multiple times is safe
- **How to validate your work** Using ping tests and CLI verification

---

## 📚 Concepts Overview

### Layer 2 vs. Layer 3

| Aspect | Layer 2 (Switching) | Layer 3 (Routing) |
|--------|---------------------|-------------------|
| **Decision Method** | MAC address lookup | IP address lookup |
| **Device** | Switch | Router |
| **VLAN** | Groups devices into broadcast domains | Not needed (routers separate domains) |
| **Ping reaches** | Any device in the same VLAN | Any device with a route |
| **Speed** | Fast (hardware-based) | Slower (CPU lookup) |

**For Task 1:** RED clients are on the same VLAN (10), so they reach each other via L2 switching.

### VLAN Concept

A **VLAN (Virtual LAN)** is like a virtual "room" on a switch. Only devices in the same room can see each other's broadcast traffic.

```
┌─────────────────────────────────────┐
│         n9k-ce01 (Switch)           │
├─────────────────────────────────────┤
│  VLAN 10 (RED)   │  VLAN 20 (No)   │
│                  │                  │
│  Eth1/3 ──────── │  (empty)         │
│  Eth1/4 ──────── │  (empty)         │
│                  │                  │
│  client1         │  (PURPLE traffic │
│  client2         │   doesn't go here)
│  (can ping)      │                  │
└─────────────────────────────────────┘
```

### Port Types

- **Access Port:** Belongs to ONE VLAN (typically client connections)
- **Trunk Port:** Carries MULTIPLE VLANs (typically switch-to-switch)
- **In this lab:** All client connections are access ports

---

## 🔗 Topology Review

**Your topology:**

```
RED CLIENTS                 ORANGE (CE)            GREEN (PE)        BLUE (Core)
client1 (23.23.23.1)   ─ Eth1/3 ┐
                              ├─ n9k-ce01
client2 (23.23.23.2)   ─ Eth1/4 ┘         ── Eth1/1 ── csr-pe01
                                                         (via data link)
                                                         
PURPLE CLIENTS
client3 (34.34.34.1)   ─ Eth1/3 ┐
                              ├─ n9k-ce02
client4 (34.34.34.2)   ─ Eth1/4 ┘         ── Eth1/1 ── csr-pe02
```

**Key facts:**
- Each client has a static IP on `eth1` (data plane)
- Each client is connected to one of the ORANGE switches
- Management IPs (172.20.20.X) are used for SSH/Ansible
- Data plane IPs (23.23.23.X, 34.34.34.X) are used for client traffic

---

## 📌 Lab Requirements

**Before starting Task 1, verify:**

- [ ] You can SSH to n9k-ce01 (172.20.20.30) as `admin`
- [ ] You can SSH to n9k-ce02 (172.20.20.31) as `admin`
- [ ] You have the SSH key at `~/.ssh/id_ed25519`
- [ ] Ansible is installed: `ansible --version`
- [ ] Your inventory file is filled in with correct IPs
- [ ] Your group_vars has correct VLAN IDs

---

## 🚀 Step-by-Step Instructions

### STEP 1: Build the Inventory File (15 minutes)

**Why:** Ansible needs to know which devices to configure and how to reach them.

**Your task:**
1. Open `lab-exercises/Task1/inventory/hosts_template.yml`
2. Replace `THIS_IP_FOR_N9K_CE01` with the actual management IP
3. Replace `THIS_IP_FOR_N9K_CE02` with the actual management IP
4. **Hint:** Check your lab notes - they start with 172.20.20...

**To verify your inventory:**
```bash
cd lab-exercises/Task1
ansible all -i inventory/hosts_reference.yml --list-hosts
# Should output:
#   n9k-ce01
#   n9k-ce02
```

**Key learning:** Without a correct inventory, Ansible can't reach any device.

---

### STEP 2: Create Variables File (10 minutes)

**Why:** Variables make playbooks reusable. Instead of hardcoding "VLAN 10", we use `{{ red_vlan.id }}`

**Your task:**
1. Create a directory: `inventory/group_vars/` (if it doesn't exist)
2. Create file: `inventory/group_vars/nxos.yml`
3. Copy from `inventory/group_vars_nxos_template.yml`
4. Verify VLAN IDs are correct (10 for RED, 20 for PURPLE)

**File structure:**
```
lab-exercises/Task1/
├── inventory/
│   ├── hosts_reference.yml
│   └── group_vars/
│       └── nxos.yml              # ← You create this
```

**Key learning:** Variables live in `group_vars/` and are automatically loaded by Ansible.

---

### STEP 3: Review the Student Playbook (10 minutes)

**Why:** Understanding WHAT you're configuring before running it.

**Your task:**
1. Open `playbooks/student/ce01_student_template.yml`
2. Answer the TODOs in the playbook (they have hints)
3. Read the comments to understand each task

**The 4 main tasks in the playbook:**
- **Task 1A:** Create VLAN 10
- **Task 1B:** Put Eth1/3 into VLAN 10 (for client1)
- **Task 1C:** Put Eth1/4 into VLAN 10 (for client2)
- **Task 1D:** Enable both interfaces (no shutdown)

**Key learning:** Playbooks are just lists of tasks. Each task does one thing.

---

### STEP 4: Fill in the Student Playbook (10 minutes)

**Your task:**
1. Open `playbooks/student/ce01_student_template.yml`
2. Replace each TODO with the correct value
   - HINT: Compare to `playbooks/solution/ce01_solution.yml`
3. Do the same for `ce02_student_template.yml`

**Things to fill in:**
- Playbook host target (which device?)
- VLAN IDs (10 or 20?)
- Variable references ({{ red_vlan.id }} or {{ purple_vlan.id }}?)

**Key learning:** Ansible playbooks are configuration as code - they show exact "what" and "how".

---

## 🎬 Running the Playbook

### Pre-run Check

```bash
cd lab-exercises/Task1

# Test SSH connectivity to devices
ansible all -i inventory/hosts_reference.yml -m ping

# Output should be:
# n9k-ce01 | SUCCESS => {
#     "ping": "pong"
# }
```

### Run the Complete Task 1

```bash
# Configure RED clients (n9k-ce01)
ansible-playbook -i inventory/hosts_reference.yml \
  playbooks/solution/ce01_solution.yml \
  -e @inventory/group_vars/nxos.yml \
  -v

# Configure PURPLE clients (n9k-ce02)
ansible-playbook -i inventory/hosts_reference.yml \
  playbooks/solution/ce02_solution.yml \
  -e @inventory/group_vars/nxos.yml \
  -v
```

**What does `-e @inventory/group_vars/nxos.yml` do?**
- `-e` = "pass extra variables"
- `@inventory/group_vars/nxos.yml` = "from this file"
- This loads the VLAN IDs and other variables

**What does `-v` do?**
- Verbose output - shows you exactly what Ansible is doing

---

## ✅ Validation

### Run the Validation Playbook

```bash
ansible-playbook -i inventory/hosts_reference.yml \
  playbooks/helper/validate_task1.yml
```

### Manual Validation (also fine)

```bash
# Test if RED clients can ping each other
docker exec clab-LTRATO-1001-linux-client1 ping -c 2 23.23.23.2

# Test if PURPLE clients can ping each other
docker exec clab-LTRATO-1001-linux-client3 ping -c 2 34.34.34.2

# Both should show: "2 packets transmitted, 2 received"
```

### Check VLAN Configuration on Switches

```bash
# SSH to n9k-ce01
ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30

# Inside the switch:
n9k-ce01# show vlan id 10
# Should show:
# VLAN Name             Status    Ports
# ---- --------------- --------- --------------------------------
# 10   RED_CLIENTS     active    Eth1/3, Eth1/4
```

---

## 📊 Expected Output

### Successful Playbook Run

```
PLAY [TASK 1: Configure n9k-ce01 for RED Clients Reachability] ****

TASK [TASK 1A: Create VLAN 10 (RED) on n9k-ce01] ****
ok: [n9k-ce01]

TASK [TASK 1B: Configure Eth1/3 (to client1) as L2 in VLAN 10] ****
changed: [n9k-ce01]

TASK [TASK 1C: Configure Eth1/4 (to client2) as L2 in VLAN 10] ****
changed: [n9k-ce01]

TASK [TASK 1D: Enable Eth1/3 and Eth1/4 (no shutdown)] ****
changed: [n9k-ce01]

PLAY RECAP ****
n9k-ce01 : ok=4 changed=3 unreachable=0 failed=0
```

**Meanings:**
- `ok` = Task ran and made no changes (already configured)
- `changed` = Task ran and made changes (new configuration applied)
- `failed` = Task did NOT run successfully

### Successful Ping

```bash
$ docker exec clab-LTRATO-1001-linux-client1 ping -c 2 23.23.23.2

PING 23.23.23.2 (23.23.23.2): 56 data bytes
64 bytes from 23.23.23.2: seq=0 ttl=64 time=2.456 ms
64 bytes from 23.23.23.2: seq=1 ttl=64 time=1.234 ms

--- 23.23.23.2 statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

---

## 🔧 Troubleshooting

### Issue 1: "Authentication failed for user admin"

**Problem:** Ansible can't SSH to switches

**Solution:**
```bash
# Verify SSH works manually
ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30

# If that fails, check:
# 1. Is the IP correct? (172.20.20.30?)
# 2. Is the key at ~/.ssh/id_ed25519?
# 3. Can you ping the IP? ping 172.20.20.30
```

### Issue 2: "No such file or directory: /path/to/hosts_reference.yml"

**Problem:** Wrong file path

**Solution:**
```bash
# Make sure you're in the right directory
cd lab-exercises/Task1

# List files to verify
ls -la inventory/
# Should show: hosts_reference.yml, hosts_template.yml
```

### Issue 3: "Clients still can't ping each other"

**Problem:** Configuration didn't apply

**Solution:**
```bash
# Check if VLAN was created
ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30
n9k-ce01# show vlan id 10

# Check if ports are in the VLAN
n9k-ce01# show interface Ethernet1/3 switchport

# Check if ports are enabled
n9k-ce01# show interface Ethernet1/3
# Should say: "Ethernet1/3 is up, line protocol is up"
```

### Issue 4: Rerun playbook and nothing changes

**This is normal!** Ansible is **idempotent** - running twice should show:

```
PLAY RECAP ****
n9k-ce01 : ok=4 changed=0 unreachable=0 failed=0
# ↑ 'changed=0' means nothing was changed (already configured)
```

This is a **good thing** - it means the configuration is stable.

---

## 📖 Playbook Walkthrough

### What Each Module Does

**Module 1: `cisco.nxos.nxos_vlans`**

```yaml
- name: "Create VLAN 10"
  cisco.nxos.nxos_vlans:
    state: present          # present = create, absent = delete
    config:
      - name: "RED_CLIENTS"
        vlan_id: 10
```

- **What it does:** Ensures VLAN 10 exists with name RED_CLIENTS
- **Equivalent CLI:** `vlan 10` then `name RED_CLIENTS`
- **Idempotent?** YES - running twice is safe

**Module 2: `cisco.nxos.nxos_l2_interfaces`**

```yaml
- name: "Configure Eth1/3 as L2 in VLAN 10"
  cisco.nxos.nxos_l2_interfaces:
    config:
      - name: "Ethernet1/3"
        access:
          vlan: 10
    state: merged           # merged = add/update, replaced = replace all
```

- **What it does:** Makes Eth1/3 an access port in VLAN 10
- **Equivalent CLI:** 
  ```
  interface Ethernet1/3
    switchport mode access
    switchport access vlan 10
  ```
- **Idempotent?** YES

**Module 3: `cisco.nxos.nxos_interfaces`**

```yaml
- name: "Enable Eth1/3"
  cisco.nxos.nxos_interfaces:
    config:
      - name: "Ethernet1/3"
        enabled: true       # true = no shutdown, false = shutdown
```

- **What it does:** Enables the interface
- **Equivalent CLI:** `no shutdown`
- **Idempotent?** YES

### How Tasks Execute

1. **Task 1A** runs first - VLAN created
2. **Task 1B** runs - Eth1/3 added to VLAN
3. **Task 1C** runs - Eth1/4 added to VLAN  
4. **Task 1D** runs - Interfaces enabled

All tasks are **sequential** - each waits for the previous to finish.

---

## 🎓 Key Takeaways

✅ **Ansible** automates repetitive network configuration tasks  
✅ **Inventory** file tells Ansible which devices exist and how to reach them  
✅ **Variables** make playbooks reusable across different devices  
✅ **Idempotency** means running playbooks multiple times is safe  
✅ **Layer 2 switching** forwards frames based on MAC addresses within VLANs  
✅ **Validation** proves your configuration works  

---

## 📝 Next Steps

After Task 1:
- [ ] RED clients can ping each other ✓
- [ ] PURPLE clients can ping each other ✓
- [ ] Ready for **Task 2: Loopback Configuration**

---

## 📞 Issues or Questions?

Refer to [TROUBLESHOOTING](#troubleshooting) section above, or ask your instructor!
