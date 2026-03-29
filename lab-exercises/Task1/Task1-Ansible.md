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

### STEP 1: Understand What Ansible Needs to Connect (5 minutes - LEARNING)

**What is happening:** Before Ansible can configure ANY device, it needs three pieces of information:

1. **Device Address:** "Where is the device?" (IP address)
2. **Login Credentials:** "How do I log in?" (username, password/key)
3. **Connection Type:** "How do I talk to it?" (SSH, Telnet, API, etc.)

Without this information, Ansible is like someone trying to call a friend without their phone number and no way to identify who they are.

**In a network context:**
- Management IP (172.20.20.30) = Phone number
- Username (admin) = Name to ask for
- SSH key (id_ed25519) = Proof of identity
- Network OS (nxos) = Language to speak

**Why this matters:** Different networks use different languages. Telling Ansible to speak "Cisco NXOS language" is like telling it to speak Spanish instead of English - same instruction, different dialect.

---

### STEP 1A: Build the Inventory File - Understanding the Structure (20 minutes)

**WHAT you're doing:**
Creating a file that Ansible reads to discover which devices exist and how to reach them.

**WHY you're doing it this way:**
Instead of hardcoding device info inside playbooks (which is messy and non-reusable), Ansible reads a separate "inventory" file. This way:
- Same playbook can manage 1 device or 100 devices
- Changing IPs only requires editing the inventory, not the playbook
- You can organize devices into groups (all NXOS switches together, all routers together, etc.)

**Deep dive: How inventory works**

Think of it like your phone contact list:

```yaml
# Phone Contact List (Inventory)
all:                          # Everyone in my contacts
  children:                   # I organize them into groups
    nxos:                     # Group: All my NXOS switch friends
      vars:                   # What they all have in common
        phone_type: "nxos"    # They're all NXOS switches
        language: "nxos_cli"  # They all speak NXOS language
      hosts:                  # Individual friends in this group
        n9k-ce01:             # Friend name: n9k-ce01
          phone: "172.20.20.30"   # Their phone number
        n9k-ce02:             # Friend name: n9k-ce02  
          phone: "172.20.20.31"   # Their phone number
```

---

## 📋 EXACT TASK: Fill in Inventory IPs

**Step 1: Open the template file**

```bash
cat lab-exercises/Task1/inventory/hosts_template.yml
```

**What you'll see:**
```yaml
---
all:
  children:
    nxos:
      vars:
        ansible_connection: network_cli
        ansible_network_os: cisco.nxos.nxos
        ansible_user: admin
        ansible_ssh_private_key_file: ~/.ssh/id_ed25519
      hosts:
        n9k-ce01:
          ansible_host: THIS_IP_FOR_N9K_CE01          ← FIND THIS LINE
        n9k-ce02:
          ansible_host: THIS_IP_FOR_N9K_CE02          ← FIND THIS LINE
```

---

**Step 2: Edit the inventory file**

Open this file in your text editor:
```bash
nano lab-exercises/Task1/inventory/hosts_template.yml
# or
code lab-exercises/Task1/inventory/hosts_template.yml
# or
vim lab-exercises/Task1/inventory/hosts_template.yml
```

---

**Step 3: Find and Replace #1 - RED Switch IP**

**Find:** 
```
          ansible_host: THIS_IP_FOR_N9K_CE01
```

**Replace with:**
```
          ansible_host: 172.20.20.30
```

**Exact before/after:**

BEFORE:
```yaml
        n9k-ce01:
          ansible_host: THIS_IP_FOR_N9K_CE01
```

AFTER:
```yaml
        n9k-ce01:
          ansible_host: 172.20.20.30
```

---

**Step 4: Find and Replace #2 - PURPLE Switch IP**

**Find:** 
```
          ansible_host: THIS_IP_FOR_N9K_CE02
```

**Replace with:**
```
          ansible_host: 172.20.20.31
```

**Exact before/after:**

BEFORE:
```yaml
        n9k-ce02:
          ansible_host: THIS_IP_FOR_N9K_CE02
```

AFTER:
```yaml
        n9k-ce02:
          ansible_host: 172.20.20.31
```

---

**Step 5: Save the file**

- **nano:** Press `Ctrl+O`, then Enter to save, then `Ctrl+X` to exit
- **code:** Press `Ctrl+S` to save
- **vim:** Press `Esc`, then `:wq` and Enter to save

---

**Step 6: Verify your changes**

```bash
# Display the file to confirm changes
cat lab-exercises/Task1/inventory/hosts_template.yml
```

**What you should see (CORRECT):**
```yaml
---
all:
  children:
    nxos:
      vars:
        ansible_connection: network_cli
        ansible_network_os: cisco.nxos.nxos
        ansible_user: admin
        ansible_ssh_private_key_file: ~/.ssh/id_ed25519
      hosts:
        n9k-ce01:
          ansible_host: 172.20.20.30         ✅ CORRECT
        n9k-ce02:
          ansible_host: 172.20.20.31         ✅ CORRECT
```

**What would be WRONG:**
```yaml
        n9k-ce01:
          ansible_host: THIS_IP_FOR_N9K_CE01  ❌ WRONG - didn't replace
```

OR

```yaml
        n9k-ce01:
          ansible_host: 172.20.20.31          ❌ WRONG - swapped IPs
```

---

**Step 7: Copy edited file to proper location**

```bash
# Copy your edited template to the actual inventory location
cp lab-exercises/Task1/inventory/hosts_template.yml lab-exercises/Task1/inventory/hosts.yml
```

---

**Step 8: Test Ansible can read the inventory**

```bash
cd lab-exercises/Task1

# List all hosts Ansible found
ansible all -i inventory/hosts.yml --list-hosts
```

**What you should see (CORRECT OUTPUT):**
```
  hosts (2):
    n9k-ce01
    n9k-ce02
```

**If you see ERROR instead (WRONG):**
```
ERROR! Unable to parse this as an YAML file. Found undefined variable: 'THIS_IP_FOR_N9K_CE01'
```
↑ This means you didn't replace the IPs. Go back to Step 3-4 and fix them.

---

**Key learning:**
- Inventory = Phonebook for your lab devices
- Ansible doesn't *know* your devices exist until you tell it via inventory
- Every Ansible command needs to point to an inventory file (`-i` flag)
- IPs must be EXACT - typos break everything

---

### STEP 1B: Actually *Test* That Ansible Can Reach Devices (10 minutes - VALIDATION)

**WHAT you're doing:** Sending a simple "hello" message to each device to confirm they're reachable

**WHY this matters:** If Ansible can't reach devices NOW, the playbooks will fail LATER. Test early!

```bash
cd lab-exercises/Task1
ansible all -i inventory/hosts.yml -m ping
```

**What this command does line by line:**
- `ansible` = Run Ansible
- `all` = Against all devices in the inventory
- `-i inventory/hosts.yml` = Using this inventory file
- `-m ping` = Use the PING module (not ICMP ping, but Ansible's ping)

**Ansible's "ping" explained:**
Ansible's ping module doesn't use network pings. Instead, it:
1. SSHs into the device
2. Checks if Python is available
3. Says "hello" via the network module
4. Expects "pong" back

---

### EXPECTED OUTPUT (CORRECT ✅)

```
n9k-ce01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
n9k-ce02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**What each line means:**
- `n9k-ce01 | SUCCESS` = Device responded, connection works
- `"ping": "pong"` = Device said hello back
- `"changed": false` = No changes made (just tested connectivity)

---

### INCORRECT OUTPUT (WRONG ❌)

**If you see this:**
```
n9k-ce01 | UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh: Permission denied (publickey).
         Timeout waiting for prompt (unable to open shell)."
}
```

**This means:**
- Inventory IP is wrong, OR
- SSH key missing, OR
- Device is powered off

---

**If you see this:**
```
ERROR! Unable to parse this as an YAML file. Found undefined variable: 'THIS_IP_FOR_N9K_CE01'
```

**This means:**
- You didn't replace the IP placeholders
- Go back to STEP 1A and fill in 172.20.20.30 and 172.20.20.31

---

**If you see this:**
```
[WARNING]: No inventory was parsed. No inventory plugin or parse plugin matched the requirements
```

**This means:**
- Wrong file path (not pointing to correct inventory file)
- Use: `-i inventory/hosts.yml` (not hosts_template.yml)

---

**Key learning:** Before running playbooks, always test basic connectivity. This saves hours of debugging!

---

### STEP 2: Create Variables File (15 minutes)

**WHAT you're doing:** Defining reusable values (VLAN IDs, port names) that multiple playbooks can use

**WHY use variables:**

Instead of this (BAD - hardcoded):
```yaml
playbook_for_ce01.yml:
  ... create VLAN 10 ...
  ... put port in VLAN 10 ...
  
playbook_for_ce02.yml:
  ... create VLAN 20 ...  
  ... put port in VLAN 20 ...
```

We write (GOOD - reusable):
```yaml
variables.yml:
  red_vlan:
    id: 10
  purple_vlan:
    id: 20

playbook_for_ce01.yml:
  ... create VLAN {{ red_vlan.id }} ...
  ... put port in VLAN {{ red_vlan.id }} ...
  
playbook_for_ce02.yml:
  ... create VLAN {{ purple_vlan.id }} ...  
  ... put port in VLAN {{ purple_vlan.id }} ...
```

**Real-world analogy:**
Imagine configuring 100 switches:
- If VLAN ID is hardcoded: Change 1 VLAN ID = edit 100 playbooks 😱
- If VLAN ID is a variable: Change 1 variable = all 100 playbooks update 🎉

**WHERE variables live in Ansible:**

Ansible automatically loads variables from specific locations:
```
inventory/
├── hosts.yml              # Device list
└── group_vars/            # ← Variables go here!
    └── nxos.yml           # Variables for "nxos" group
```

**How Ansible finds variables:**
1. You run: `ansible-playbook -i inventory/hosts.yml playbook.yml`
2. Ansible reads inventory file
3. Identifies device group: `nxos`
4. Looks for: `inventory/group_vars/nxos.yml` ← automatically!
5. Loads all variables from that file

---

## 🎯 EXACT STEP-BY-STEP

### Step 1: Create the group_vars directory (if missing)

```bash
mkdir -p lab-exercises/Task1/inventory/group_vars
```

**What this does:**
- `-p` = Create parent directories if needed
- Creates: `lab-exercises/Task1/inventory/group_vars/` folder

---

### Step 2: Check the template file

```bash
cat lab-exercises/Task1/inventory/group_vars_nxos_template.yml
```

**What you should see:**
```yaml
---
# VLAN Configuration Variables

red_vlan:
  id: 10
  name: "RED_CLIENTS"
  description: "RED clients (client1 and client2)"
  ports:
    - Ethernet1/3
    - Ethernet1/4

purple_vlan:
  id: 20
  name: "PURPLE_CLIENTS"
  description: "PURPLE clients (client3 and client4)"
  ports:
    - Ethernet1/3
    - Ethernet1/4
```

---

### Step 3: Copy the template to the actual location

```bash
cp lab-exercises/Task1/inventory/group_vars_nxos_template.yml \
   lab-exercises/Task1/inventory/group_vars/nxos.yml
```

**What this does:**
- Copies the template file
- Places it in the correct location
- Renames it to `nxos.yml` (Ansible looks for this file)

---

### Step 4: Verify the file was created correctly

```bash
cat lab-exercises/Task1/inventory/group_vars/nxos.yml
```

**What you should see (CORRECT ✅):**
```yaml
---
# VLAN Configuration Variables

red_vlan:
  id: 10
  name: "RED_CLIENTS"
  description: "RED clients (client1 and client2)"
  ports:
    - Ethernet1/3
    - Ethernet1/4

purple_vlan:
  id: 20
  name: "PURPLE_CLIENTS"
  description: "PURPLE clients (client3 and client4)"
  ports:
    - Ethernet1/3
    - Ethernet1/4
```

---

### Step 5: Verify Ansible can read the file

```bash
python3 -c "import yaml; yaml.safe_load(open('lab-exercises/Task1/inventory/group_vars/nxos.yml'))" && echo "✅ Variables file OK"
```

**What you should see (CORRECT ✅):**
```
✅ Variables file OK
```

**If you see ERROR (WRONG ❌):**
```
yaml.scanner.ScannerError: mapping values are not allowed here
```

This means:
- YAML indentation is wrong (must be 2 spaces, not tabs)
- Check the file again - copy exactly from template

---

### Step 6: View directory structure to confirm everything

```bash
tree lab-exercises/Task1/inventory/
```

**What you should see (CORRECT ✅):**
```
lab-exercises/Task1/inventory/
├── group_vars
│   └── nxos.yml                  ← ✅ This file should exist
├── group_vars_nxos_reference.yml
├── group_vars_nxos_template.yml
├── hosts.yml                      ← ✅ This file (you created from template)
├── hosts_reference.yml
└── hosts_template.yml
```

**If you can't see `group_vars/nxos.yml` (WRONG ❌):**
- Go back to Step 3 and copy the file again
- Make sure file is named EXACTLY `nxos.yml`

---

**Key learning:**
- Variables live in `group_vars/` and are automatically loaded by Ansible
- YAML spacing matters (2-space indentation required)
- Ansible looks for: `group_vars/<groupname>.yml` automatically

---

### STEP 3: Understand the Playbook Structure (15 minutes - EDUCATION)

**WHAT is a playbook:**
A playbook is a file that tells Ansible "what devices to touch" and "what to do on each device".

**STRUCTURE of every playbook:**

```yaml
---                              # YAML file start marker
- name: "Description"            # This play's description
  hosts: "device_group"          # WHICH devices (from inventory)
  gather_facts: false            # Don't waste time collecting device info
  
  tasks:                         # LIST OF THINGS TO DO
    - name: "Task 1 description"
      module_name:               # What module to use
        parameter: value         # How to configure it
    
    - name: "Task 2 description"
      another_module:
        parameter: value
```

**Real-world analogy - Recipe:**
```yaml
Recipe (Playbook):
  Device: n9k-ce01 (which oven?)
  
  Steps:
    Step 1: Create VLAN 10
      - Name: RED_CLIENTS
      - ID: 10
    
    Step 2: Configure Eth1/3
      - Port: Ethernet1/3
      - VLAN: 10
      - Mode: Access
    
    Step 3: Enable Eth1/3
      - Interface: Ethernet1/3
      - Command: no shutdown
```

**MODULE = A tool that does ONE specific thing**

Example modules:
- `cisco.nxos.nxos_vlans` = Create/delete VLANs (ONE job)
- `cisco.nxos.nxos_l2_interfaces` = Configure port as L2 (ONE job)
- `cisco.nxos.nxos_interfaces` = Enable/disable ports (ONE job)

**PARAMETERS = Settings for that module**

Example:
```yaml
- name: "Create VLAN 10"
  cisco.nxos.nxos_vlans:        # Module: Create VLANs
    state: merged               # Parameter: merged = create/update
    config:                     # Parameter: what config to apply
      - name: "RED_CLIENTS"     # Sub-parameter: VLAN name
        vlan_id: 10             # Sub-parameter: VLAN ID
```

**What each task in our playbook does:**

**Task 1A: Create VLAN**
```yaml
- name: "Create VLAN 10"
  cisco.nxos.nxos_vlans:
    state: merged
    config:
      - name: "RED_CLIENTS"
        vlan_id: 10
```
- Tells n9k-ce01: "VLAN 10 should exist and be named RED_CLIENTS"
- CLI equivalent: `vlan 10` + `name RED_CLIENTS`
- Idempotent: Running twice is safe (VLAN 10 already exists, no change)

**Task 1B & 1C: Configure Ports as L2**
```yaml
- name: "Configure Eth1/3 as Access Port in VLAN 10"
  cisco.nxos.nxos_l2_interfaces:
    config:
      - name: "Ethernet1/3"
        access:
          vlan: 10
    state: merged
```
- Tells n9k-ce01: "Ethernet1/3 should be an access port in VLAN 10"
- CLI equivalent: `interface Eth1/3` → `switchport mode access` → `switchport access vlan 10`
- Effect: Traffic from client1 gets tagged with VLAN 10
- Idempotent: Running twice makes no changes (port already configured)

**Task 1D: Enable Ports**
```yaml
- name: "Enable Eth1/3 and Eth1/4"
  cisco.nxos.nxos_interfaces:
    config:
      - name: "Ethernet1/3"
        enabled: true
```
- Tells n9k-ce01: "Interface Ethernet1/3 should be UP (not shutdown)"
- CLI equivalent: `interface Eth1/3` → `no shutdown`
- Effect: Port becomes active and starts forwarding traffic
- Idempotent: Running twice makes no changes (port already enabled)

**EXECUTION ORDER:**
Playbook runs tasks sequentially:
1. Task 1A creates VLAN 10
2. Task 1B puts Eth1/3 in VLAN 10 (VLAN must exist first!)
3. Task 1C puts Eth1/4 in VLAN 10
4. Task 1D enables both ports

**Can they run out of order?** NO - Task 1B fails if Task 1A didn't run first (VLAN doesn't exist).

**Key learning:**
- Playbooks = ordered lists of configuration steps
- Modules = individual tools that do ONE thing
- Parameters = settings for each tool
- Order matters (VLAN before port assignment)

---

### STEP 4: Complete the Student Template Playbooks (20 minutes - PRACTICE)

**WHAT you're doing:** Filling in the TODOs to complete working playbooks

**WHY:** Half-filled templates teach you to READ and UNDERSTAND playbook syntax instead of just copy-pasting

---

## 🎯 EXACTLY WHAT TO FILL IN

### Task A: Fill in ce01_student_template.yml (RED Clients)

**Step 1: Open the student template**

```bash
cat lab-exercises/Task1/playbooks/student/ce01_student_template.yml
```

**What you'll see (FULL FILE):**
```yaml
---
- name: "TASK 1: Configure n9k-ce01 for RED Clients Reachability"
  hosts: ???                                          # ← TODO #1: FIND THIS

  gather_facts: false

  tasks:
    - name: "TASK 1A: Create VLAN 10 (RED) on n9k-ce01"
      cisco.nxos.nxos_vlans:
        state: ???                                   # ← TODO #2: FIND THIS
        config:
          - name: "{{ red_vlan.name }}"
            vlan_id: "{{ red_vlan.id }}"

    - name: "TASK 1B: Configure Eth1/3 (to client1) as L2 in VLAN 10"
      cisco.nxos.nxos_l2_interfaces:
        config:
          - name: "Ethernet1/3"
            access:
              vlan: "{{ ??? }}"                     # ← TODO #3: FIND THIS
        state: merged

    - name: "TASK 1C: Configure Eth1/4 (to client2) as L2 in VLAN 10"
      cisco.nxos.nxos_l2_interfaces:
        config:
          - name: "Ethernet1/4"
            access:
              vlan: "{{ ??? }}"                     # ← TODO #4: FIND THIS
        state: merged

    - name: "TASK 1D: Enable Eth1/3 and Eth1/4 (no shutdown)"
      cisco.nxos.nxos_interfaces:
        config:
          - name: "Ethernet1/3"
            enabled: true
          - name: "Ethernet1/4"
            enabled: true
        state: merged
```

---

### TODO #1: Fix the `hosts:` line

**Find (line 2):**
```yaml
  hosts: ???
```

**Replace with:**
```yaml
  hosts: nxos
```

**Why:** This tells Ansible "run on devices in the nxos group from inventory"

**Before/After:**
```yaml
BEFORE:
- name: "TASK 1: Configure n9k-ce01 for RED Clients Reachability"
  hosts: ???

AFTER:
- name: "TASK 1: Configure n9k-ce01 for RED Clients Reachability"
  hosts: nxos
```

---

### TODO #2: Fix the `state:` in Task 1A

**Find (line 12):**
```yaml
        state: ???
```

**Replace with:**
```yaml
        state: merged
```

**Why:** NXOS modules use "merged" (not "present") to create/update VLANs

**Before/After:**
```yaml
BEFORE:
    - name: "TASK 1A: Create VLAN 10 (RED) on n9k-ce01"
      cisco.nxos.nxos_vlans:
        state: ???
        config:

AFTER:
    - name: "TASK 1A: Create VLAN 10 (RED) on n9k-ce01"
      cisco.nxos.nxos_vlans:
        state: merged
        config:
```

---

### TODO #3: Fix the vlan reference in Task 1B

**Find (line 23, inside Task 1B):**
```yaml
              vlan: "{{ ??? }}"
```

**Replace with:**
```yaml
              vlan: "{{ red_vlan.id }}"
```

**Why:** This pulls VLAN ID from variables (equals "10")

**Before/After:**
```yaml
BEFORE:
    - name: "TASK 1B: Configure Eth1/3 (to client1) as L2 in VLAN 10"
      cisco.nxos.nxos_l2_interfaces:
        config:
          - name: "Ethernet1/3"
            access:
              vlan: "{{ ??? }}"
        state: merged

AFTER:
    - name: "TASK 1B: Configure Eth1/3 (to client1) as L2 in VLAN 10"
      cisco.nxos.nxos_l2_interfaces:
        config:
          - name: "Ethernet1/3"
            access:
              vlan: "{{ red_vlan.id }}"
        state: merged
```

---

### TODO #4: Fix the vlan reference in Task 1C

**Find (line 32, inside Task 1C):**
```yaml
              vlan: "{{ ??? }}"
```

**Replace with:**
```yaml
              vlan: "{{ red_vlan.id }}"
```

**Why:** Same as TODO #3 - also needs red_vlan.id for VLAN 10

**Before/After:**
```yaml
BEFORE:
    - name: "TASK 1C: Configure Eth1/4 (to client2) as L2 in VLAN 10"
      cisco.nxos.nxos_l2_interfaces:
        config:
          - name: "Ethernet1/4"
            access:
              vlan: "{{ ??? }}"
        state: merged

AFTER:
    - name: "TASK 1C: Configure Eth1/4 (to client2) as L2 in VLAN 10"
      cisco.nxos.nxos_l2_interfaces:
        config:
          - name: "Ethernet1/4"
            access:
              vlan: "{{ red_vlan.id }}"
        state: merged
```

---

### Step 2: Save your changes

```bash
# Save in your editor (Ctrl+S in most editors)
```

---

### Step 3: Do the same for ce02_student_template.yml (PURPLE Clients)

**Open the template:**
```bash
cat lab-exercises/Task1/playbooks/student/ce02_student_template.yml
```

**The TODOs are identical, EXCEPT for the VLAN variable:**
- TODO #1: `hosts:` → Replace with `nxos`
- TODO #2: `state:` → Replace with `merged`
- TODO #3: `vlan:` → Replace with `{{ purple_vlan.id }}` ← DIFFERENT! (not red_vlan)
- TODO #4: `vlan:` → Replace with `{{ purple_vlan.id }}` ← DIFFERENT! (not red_vlan)

**Why the difference?**
- ce01 is for RED clients (VLAN 10) → uses `red_vlan.id`
- ce02 is for PURPLE clients (VLAN 20) → uses `purple_vlan.id`
- When variables are substituted:
  - ce01: `{{ red_vlan.id }}` becomes 10
  - ce02: `{{ purple_vlan.id }}` becomes 20

**Exact for ce02_student_template.yml:**

Find line 2:
```yaml
  hosts: ???
```
Replace with:
```yaml
  hosts: nxos
```

Find line 12:
```yaml
        state: ???
```
Replace with:
```yaml
        state: merged
```

Find line 23:
```yaml
              vlan: "{{ ??? }}"
```
Replace with:
```yaml
              vlan: "{{ purple_vlan.id }}"
```

Find line 32:
```yaml
              vlan: "{{ ??? }}"
```
Replace with:
```yaml
              vlan: "{{ purple_vlan.id }}"
```

---

### Step 4: Verify your changes

**Compare ce01 to the solution:**
```bash
diff lab-exercises/Task1/playbooks/student/ce01_student_template.yml \
     lab-exercises/Task1/playbooks/solution/ce01_solution.yml
```

**What you should see (if correct):**
```
# No output at all = Perfect match! ✅
```

**If you see differences:**
```
< state: ???
> state: merged
```
This means you missed a TODO. Go back and fix it.

---

**Compare ce02 to the solution:**
```bash
diff lab-exercises/Task1/playbooks/student/ce02_student_template.yml \
     lab-exercises/Task1/playbooks/solution/ce02_solution.yml
```

**What you should see (if correct):**
```
# No output at all = Perfect match! ✅
```

---

**KEY INSIGHT:**
After filling in these templates, you understand:
- Playbook structure (hosts, tasks, modules)
- Variable substitution (`{{ variable.subproperty }}`)
- Module parameters (state, config, name, vlan, enabled)
- Why NXOS uses "merged" not "present"
- How templates make you think through each step

**Key learning:**
- Templates = guided learning, not just copy-paste
- Solution comparison teaches you proper syntax
- Variable substitution = code reusability

---

## 🎬 STEP 5: Pre-Flight Checks (10 minutes)

**WHAT you're doing:** Verifying everything is ready BEFORE running the playbook

**WHY:** Running a playbook against unconfigured devices can cause issues that are hard to debug. Pre-flight checks catch mistakes early.

### Step 5A: Verify Directory Structure

**WHAT this does:** Confirms all files are in the right places

```bash
cd lab-exercises/Task1

# List the structure
tree -L 3
```

**Expected output:**
```
Task1/
├── inventory/
│   ├── group_vars/
│   │   └── nxos.yml           # ← You created this
│   ├── hosts_reference.yml    # ← Your filled IPs
│   └── hosts_template.yml
├── playbooks/
│   ├── helper/
│   │   └── validate_task1.yml
│   ├── solution/
│   │   ├── ce01_solution.yml
│   │   └── ce02_solution.yml
│   └── student/
│       ├── ce01_student_template.yml
│       └── ce02_student_template.yml
├── Task1-Ansible.md
└── README.md
```

**If files are missing:**
- Copy from template, verify you saved them

### Step 5B: Verify Inventory File Syntax

**WHAT this does:** YAML has STRICT spacing rules. Wrong indentation = broken playbook

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('inventory/hosts_reference.yml'))" && echo "✓ Inventory syntax OK"
```

**If you get an error:**
- YAML indentation is wrong (must be 2 spaces, not tabs)
- Check the template again - spacing MUST match exactly

### Step 5C: Verify Variables File Syntax

```bash
python3 -c "import yaml; yaml.safe_load(open('inventory/group_vars/nxos.yml'))" && echo "✓ Variables syntax OK"
```

### Step 5D: Verify Playbook Syntax

```bash
ansible-playbook --syntax-check playbooks/solution/ce01_solution.yml && echo "✓ PlaybookSyntax OK"
ansible-playbook --syntax-check playbooks/solution/ce02_solution.yml && echo "✓ Playbook Syntax OK"
```

**What this does:**
- `--syntax-check` = Parse playbook for errors without actually running it
- Catches mistakes like: wrong indentation, missing colons, invalid module names
- Saves time - fixes syntax errors BEFORE trying to reach devices

**Key learning:**
- YAML is whitespace-sensitive (unlike programming languages)
- Always syntax-check before running
- Pre-flight saves hours of debugging

### Step 5E: Test Basic Connectivity

**WHAT this does:** Confirms Ansible can SSH to each device

```bash
cd lab-exercises/Task1

# Run Ansible's built-in ping test
ansible all -i inventory/hosts_reference.yml -m ping
```

**Expected output:**
```
n9k-ce01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
n9k-ce02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**Line-by-line explanation:**

| Part | Meaning |
|------|---------|
| `ansible` | Run Ansible |
| `all` | Against every device in inventory |
| `-i inventory/hosts_reference.yml` | Using this inventory file (tells Ansible which devices exist) |
| `-m ping` | Using the PING module (test connectivity) |

**What happens when you run this:**
1. Ansible reads your inventory file
2. Finds: n9k-ce01 at 172.20.20.30, n9k-ce02 at 172.20.20.31
3. For EACH device:
   - Opens SSH connection
   - Loads NXOS module on device
   - Sends module a "ping" request
   - Waits for "pong" response
4. Returns results showing which devices responded

**If you see UNREACHABLE:**

| Error | Root Cause | Fix |
|-------|-----------|-----|
| "Permission denied" | Wrong SSH key | Check: `ls -la ~/.ssh/id_ed25519` |
| "Connection refused" | Device not running | Check: `docker ps \| grep -E "ce01\|ce02"` |
| "Name or service not known" | Inventory IP typo | Verify in hosts_reference.yml |
| "Timeout" | Network unreachable | Check management network connectivity |

**Key insight:**
If this ping test PASSES, Ansible can reach the devices. If it FAILS, playbook will fail too (no point running).

---

## 🏃 STEP 6: Run the Configuration Playbook (20 minutes - ACTION)

**WHAT you're doing:** Executing the playbook to actually configure the switches

**WHY this works:** Your playbook is a sequential instruction list. When you run it, Ansible:
1. Logs into n9k-ce01
2. Runs each task in order
3. If task A fails, stops (won't run task B)
4. Reports what it did

---

### Step 6A: Configure RED Clients (n9k-ce01)

**WHAT this does:**
- Creates VLAN 10 on switch
- Assigns Ethernet1/3 and Ethernet1/4 to VLAN 10
- Enables both ports

---

**Step 6A.1: Run the command**

```bash
cd lab-exercises/Task1

# Run the RED playbook
ansible-playbook \
  -i inventory/hosts.yml \
  playbooks/solution/ce01_solution.yml \
  -e @inventory/group_vars/nxos.yml \
  -v
```

**Command breakdown - EXACTLY what to type:**

| Part | Meaning | Example |
|------|---------|---------|
| `ansible-playbook` | Run a playbook | Literal command |
| `-i inventory/hosts.yml` | Use YOUR inventory file | `-i` = inventory flag |
| `playbooks/solution/ce01_solution.yml` | Run THIS playbook file | File path (don't change) |
| `-e @inventory/group_vars/nxos.yml` | Load variables | `-e @` = load from file |
| `-v` | Show detailed output | Verbose flag |

---

**Step 6A.2: What you'll see (CORRECT OUTPUT ✅)**

**First, you'll see the play header:**
```
[WARNING]: No password was provided for elevated privilege, assuming unprivileged execution

PLAY [TASK 1: Configure n9k-ce01 for RED Clients Reachability] ****
```

↑ The WARNING is normal and can be ignored.

---

**Next, you'll see each TASK execute:**

```
TASK [TASK 1A: Create VLAN 10 (RED) on n9k-ce01] ****
changed: [n9k-ce01]
```

**What this means:**
- Task ran successfully
- `changed: [n9k-ce01]` = This device had changes made to it
- VLAN 10 was created because it didn't exist before

---

```
TASK [TASK 1B: Configure Eth1/3 (to client1) as L2 in VLAN 10] ****
changed: [n9k-ce01]
```

**What this means:**
- Ethernet1/3 was configured as access port in VLAN 10
- CLI equivalent ran: `interface Eth1/3` → `switchport mode access` → `switchport access vlan 10`

---

```
TASK [TASK 1C: Configure Eth1/4 (to client2) as L2 in VLAN 10] ****
changed: [n9k-ce01]
```

**What this means:**
- Ethernet1/4 was configured as access port in VLAN 10
- Same as Task 1B, but for the other port

---

```
TASK [TASK 1D: Enable Eth1/3 and Eth1/4 (no shutdown)] ****
changed: [n9k-ce01]
```

**What this means:**
- Both ports were enabled (no shutdown)
- Ports are now in "up" state
- Traffic can now flow

---

**Finally, you'll see the summary:**

```
PLAY RECAP ****
n9k-ce01 : ok=4 changed=4 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

**What each metric means:**

| Metric | Value | Meaning |
|--------|-------|---------|
| `ok=4` | 4 tasks | All 4 tasks ran successfully |
| `changed=4` | 4 changes | All 4 tasks made changes (first run) |
| `unreachable=0` | No unreachable | Device WAS reachable |
| `failed=0` | No failures | ✅ **SUCCESS** |

---

**If you see anything different, it's a PROBLEM:**

**Problem: `failed=1`**
```
PLAY RECAP ****
n9k-ce01 : ok=2 changed=2 unreachable=0 failed=1 skipped=0
```
↑ One task failed (check error above the RECAP)

**Problem: `unreachable=1`**
```
PLAY RECAP ****
n9k-ce01 : ok=0 changed=0 unreachable=1 failed=0 skipped=0
```
↑ Ansible couldn't reach the device (IP wrong? SSH key missing?)

**Problem: `changed=0`**
```
PLAY RECAP ****
n9k-ce01 : ok=4 changed=0 unreachable=0 failed=0 skipped=0
```
↑ Configuration already existed (run again to verify - still `changed=0` is normal)

---

### Step 6B: Configure PURPLE Clients (n9k-ce02)

**WHAT this does:**
- Creates VLAN 20 on switch
- Assigns Ethernet1/3 and Ethernet1/4 to VLAN 20
- Enables both ports

---

**Step 6B.1: Run the command**

```bash
# Run the PURPLE playbook
ansible-playbook \
  -i inventory/hosts.yml \
  playbooks/solution/ce02_solution.yml \
  -e @inventory/group_vars/nxos.yml \
  -v
```

---

**Step 6B.2: What you should see (CORRECT OUTPUT ✅)**

Same structure as Step 6A, but for n9k-ce02:

```
PLAY [TASK 1: Configure n9k-ce02 for PURPLE Clients Reachability] ****

TASK [TASK 1A: Create VLAN 20 (PURPLE) on n9k-ce02] ****
changed: [n9k-ce02]

TASK [TASK 1B: Configure Eth1/3 (to client3) as L2 in VLAN 20] ****
changed: [n9k-ce02]

TASK [TASK 1C: Configure Eth1/4 (to client4) as L2 in VLAN 20] ****
changed: [n9k-ce02]

TASK [TASK 1D: Enable Eth1/3 and Eth1/4 (no shutdown)] ****
changed: [n9k-ce02]

PLAY RECAP ****
n9k-ce02 : ok=4 changed=4 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

**Key learning:**
- Both playbooks configure identical logic (VLAN + ports)
- Only difference: which device (n9k-ce02 vs n9k-ce01), which VLAN ID (20 vs 10)
- Variables substitution makes this possible (same playbook, different values)

---

## ✅ STEP 7: Validate - Does It Actually Work? (25 minutes)

**WHAT you're doing:** Verifying your configuration works in practice

**WHY:** Configuration on switch ≠ traffic actually flows. We test to confirm end-to-end connectivity.

### Step 7A: Automatic Validation - Run Helper Playbook

**WHAT this does:**
- Checks if VLANs exist
- Checks if interfaces are in VLANs
- Checks if ports are enabled
- Runs ping tests between clients

```bash
# Run validation playbook
ansible-playbook \
  -i inventory/hosts.yml \
  playbooks/helper/validate_task1.yml \
  -v
```

**This runs 4 test groups:**

| Test | What It Checks |
|------|----------------|
| Test 1: VLAN Existence | Does VLAN 10 exist? Is port Eth1/3 in it? |
| Test 2: VLAN Existence | Does VLAN 20 exist? Is port Eth1/3 in it? |
| Test 3: Client Ping | Can client1 (23.23.23.1) ping client2 (23.23.23.2)? |
| Test 4: Client Ping | Can client3 (34.34.34.1) ping client4 (34.34.34.2)? |

**Expected output:**
```
TASK [Test 1: Check VLAN 10 exists on n9k-ce01] ****
VLAN 10   RED_CLIENTS                   active    Eth1/3, Eth1/4
ok: [n9k-ce01]

TASK [Test 3: Ping from client1 to client2] ****
2 packets transmitted, 2 received
ok: [n9k-ce01]
```

**If all say "ok": ✅ SUCCESS - your configuration works!**

### Step 7B: Manual Validation - Test Connectivity Directly

**WHAT this does:** Runs ping commands from client containers to verify they can talk

**Why manual testing:**
- Confirms containers are running
- Disproves "ping module is broken" theories
- Shows real packet flow

**RED Clients Test:**

```bash
# Test if client1 can ping client2
docker exec clab-LTRATO-1001-linux-client1 ping -c 2 23.23.23.2
```

**Command breakdown:**
| Part | Meaning |
|------|---------|
| `docker exec` | Run command inside container |
| `clab-LTRATO-1001-linux-client1` | In this specific container |
| `ping` | Send ICMP ping packets |
| `-c 2` | Send exactly 2 packets (don't ping forever) |
| `23.23.23.2` | To this IP address |

**What happens when you run this:**
1. Docker finds container: linux-client1
2. Executes: `ping 23.23.23.2`
3. Sends 2 ICMP echo request packets from 23.23.23.1
4. Through docker network interface connected to Eth1/3
5. Through Ethernet1/3 switch port (in VLAN 10)
6. To client2 connected via Ethernet1/4 (also in VLAN 10)
7. client2 sees destination IP 23.23.23.2 matches its IP
8. Sends ping reply back
9. client1 receives reply

**Expected output:**
```
PING 23.23.23.2 (23.23.23.2): 56 data bytes
64 bytes from 23.23.23.2: seq=0 ttl=64 time=2.456 ms
64 bytes from 23.23.23.2: seq=1 ttl=64 time=1.234 ms

--- 23.23.23.2 statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 1.234/1.845/2.456 ms
```

**Success indicators:**
- ✅ "2 packets transmitted, 2 packets received"
- ✅ "0% packet loss"
- ✅ Round-trip times are reasonable (1-10ms for lab)

**PURPLE Clients Test:**

```bash
# Test if client3 can ping client4
docker exec clab-LTRATO-1001-linux-client3 ping -c 2 34.34.34.2
```

**If BOTH tests show 0% loss:** 

🎉 **TASK 1 IS COMPLETE AND WORKING!**

### Step 7C: Deep Validation - SSH to Switch and Verify Manually

**WHAT this does:** Connects directly to switch to inspect configuration

**WHY:** Confirms what's actually configured vs. what Ansible thinks is configured

```bash
# SSH to RED switch
ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30
```

**Once inside the switch, run these commands:**

```
# Show all VLANs
n9k-ce01# show vlan

# Show specific VLAN
n9k-ce01# show vlan id 10
# OUTPUT SHOULD BE:
# VLAN Name             Status    Ports
# ---- --------------- --------- -----
# 10   RED_CLIENTS     active    Eth1/3, Eth1/4

# Show Ethernet1/3 status
n9k-ce01# show interface Ethernet1/3
# OUTPUT SHOULD SHOW:
# Ethernet1/3 is up, admin state is up
# Port mode is access
# Access VLANs: 10

# Show Ethernet1/4 status
n9k-ce01# show interface Ethernet1/4

# Exit
n9k-ce01# exit
```

**What each command tells you:**

| Command | Verifies |
|---------|----------|
| `show vlan` | Does VLAN exist? With correct name? Which ports? |
| `show interface Eth1/3` | Is port up? Is it access mode? Which VLAN assigned? |

**If you see:**
- `VLAN 10 ... Eth1/3, Eth1/4` → ✅ VLAN configured correctly
- `Ethernet1/3 is up ... Port mode is access ... Access VLAN 10` → ✅ Port configured correctly

---

## 📊 STEP 8: Understanding What Happened (15 minutes - REFLECTION)

**WHAT this step does:** Deep dive into what was actually configured and why it works

### What Did We Just Configure?

**Layer 2 Network Setup on n9k-ce01:**

```
┌─────────────────────────────────────┐
│         n9k-ce01 (Switch)           │
│  ┌─────────────────────────────────┐│
│  │      VLAN 10 (RED_CLIENTS)      ││
│  │    Ethernet1/3 | Ethernet1/4    ││
│  │    (CLIENT1)   | (CLIENT2)      ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
         ↓             ↓
   [client1]     [client2]
   23.23.23.1    23.23.23.2
```

**What the VLAN does:**
- Creates a logical broadcast domain #10
- Ethernet1/3 is a member of VLAN 10
- Ethernet1/4 is a member of VLAN 10
- When client1 sends broadcast: reaches ALL ports in VLAN 10 (including Eth1/4 to client2)
- When client2 sends broadcast: reaches ALL ports in VLAN 10 (including Eth1/3 to client1)
- Broadcast domain between them = can ping each other

**What "Access Port" means:**
- Port is unaware of VLANs
- Whatever traffic comes from client1 → gets VLAN 10 tag added
- Traffic with VLAN 10 tag → goes to all access ports in VLAN 10
- Client1 sends frame → switch adds VLAN 10 tag → client2 receives frame

**Why they can ping:**
1. client1 needs to reach 23.23.23.2
2. Doesn't know IP is local, sends ARP broadcast
3. ARP = broadcast frame (sent to all ports in VLAN)
4. Goes to Eth1/4 → client2 hears it
5. client2 responds with ARP reply
6. client1 learns: 23.23.23.2 is on Eth1/4
7. Sends ping frame to Eth1/4
8. client2 receives ping, replies
9. Ping succeeds!

**Key learning:**
- VLANs are Layer 2 broadcast domains
- Access ports bridge clients to broadcast domain
- Broadcast frames reach all access ports in VLAN
- This is how client1 finds client2 via ARP
- This is why ping works

### The Ansible Playbook Flow

**What happened when you ran the playbook:**

```
You run: ansible-playbook -i inventory/hosts_reference.yml ...
    ↓
Ansible reads inventory → finds devices: n9k-ce01, n9k-ce02
    ↓
Ansible reads playbook → finds 4 tasks for n9k-ce01
    ↓
Ansible reads variables → loads red_vlan.id = 10
    ↓
Task 1A: Create VLAN → {{ red_vlan.id }} substitutes to 10
    ↓
Ansible connects SSH to 172.20.20.30 → reaches n9k-ce01
    ↓
Ansible loads nxos_vlans module → creates VLAN 10
    ↓
Task 1B: Configure Eth1/3 → same SSH session
    ↓
Ansible loads nxos_l2_interfaces module → sets Eth1/3 to VLAN 10
    ↓
Task 1C: Configure Eth1/4 → same SSH session
    ↓
Ansible loads nxos_l2_interfaces module → sets Eth1/4 to VLAN 10
    ↓
Task 1D: Enable ports → same SSH session
    ↓
Ansible loads nxos_interfaces module → enables Eth1/3 and Eth1/4
    ↓
SSH session closes
    ↓
Ansible reports: ok=4 changed=4
    ↓
You test ping → works → Task 1 complete!
```

**Idempotency explained:**

**First run:**
- VLAN 10 doesn't exist → create it → changed=1
- Eth1/3 not in VLAN → configure it → changed=1
- Eth1/4 not in VLAN → configure it → changed=1
- Eth1/3 disabled → enable it → changed=1
- Total: changed=4

**Second run (if you run again):**
- VLAN 10 exists with correct config → no change → changed=0
- Eth1/3 already in VLAN 10 → no change → changed=0
- Eth1/4 already in VLAN 10 → no change → changed=0
- Eth1/3 already enabled → no change → changed=0
- Total: changed=0

**Why this is powerful:**
- You can run playbook 1, 10, 100 times = same result
- No "double configuration" issues
- Safe to re-run if unsure (won't break anything)
- This is Infrastructure as Code best practice

---

## ✅ STEP 9: Troubleshooting (Reference)

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

## ✅ STEP 9: Troubleshooting Common Issues (Reference)

**WHAT this section does:** Explains what to do when things go wrong

**WHY troubleshooting matters:** Even perfect playbooks can fail due to:
- Network connectivity issues
- Typos in configuration files
- Device not responding
- Permissions problems

**Learning goal:** Instead of just "fixing" problems, understand WHY they happen.

### Issue 1: "ERROR: Permission denied (publickey)"

**WHAT this error means:**
```
n9k-ce01 | UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh: ... Permission denied (publickey)"
}
```

**WHY this happens:**
- Ansible tried to SSH using a key
- Device said "I don't recognize that key"
- Connection rejected before any commands ran

**ROOT CAUSES - In order to check:**

1. **SSH key isn't at the right path**
   ```bash
   # Ansible looks for: ~/.ssh/id_ed25519
   ls -la ~/.ssh/id_ed25519
   # If file doesn't exist:
   # ERROR: No such file or directory
   # FIX: Copy key to ~/.ssh/id_ed25519 or create it
   ```

2. **SSH key permissions are wrong**
   ```bash
   # SSH keys have strict permissions (600 = only owner can read/write)
   ls -la ~/.ssh/id_ed25519
   # Should show: -rw------- 1 user user ...
   # If different, fix it:
   chmod 600 ~/.ssh/id_ed25519
   ```

3. **Device's authorized_keys doesn't have your public key**
   ```bash
   # When you SSH, device matches your private key against its authorized_keys
   # If public key never installed: connection refused
   # Check by manually SSHing:
   ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30
   # If that fails, the lab admin needs to install your public key
   ```

4. **Wrong username in inventory**
   ```bash
   # Inventory says: ansible_user: admin
   # But device expects: network
   # Fix in hosts_reference.yml: ansible_user: [correct_username]
   ```

**DEBUGGING STEPS:**

```bash
# Step 1: Test SSH manually
ssh -v -i ~/.ssh/id_ed25519 admin@172.20.20.30
# -v = verbose (shows details)
# Shows exactly where it's failing

# Step 2: Check if device is reachable
ping 172.20.20.30
# If "Destination unreachable": network problem, not auth

# Step 3: Verify key file
file ~/.ssh/id_ed25519
# Should say: "private key"

# Step 4: Check Ansible sees the key
ansible all -i inventory/hosts_reference.yml -vvv
# -vvv = extra extra verbose
# Shows full connection debug info
```

**FIX PRIORITY:**
1. Check IP address is correct
2. Check key exists and has right permissions
3. Test manual SSH
4. Check inventory username

---

### Issue 2: "ERROR: No such file or directory"

**WHAT this error means:**
```
ERROR! [Errno 2] No such file or directory: '/path/to/hosts_reference.yml'
```

**WHY this happens:**
- Ansible tried to open a file
- File doesn't exist at that path
- Playbook execution stopped

**ROOT CAUSES:**

1. **Wrong working directory**
   ```bash
   # You ran:
   ansible-playbook -i inventory/hosts_reference.yml playbooks/solution/ce01_solution.yml
   
   # Ansible looked in: <current_dir>/inventory/hosts_reference.yml
   # But you need: <current_dir>/lab-exercises/Task1/inventory/hosts_reference.yml
   
   # FIX: Change to right directory
   cd lab-exercises/Task1
   
   # Then relative paths work:
   ansible-playbook -i inventory/hosts_reference.yml playbooks/solution/ce01_solution.yml
   ```

2. **File doesn't exist at all**
   ```bash
   # List what files DO exist
   ls -la inventory/
   
   # If hosts_reference.yml is missing:
   # FIX: Copy from hosts_template.yml and fill in IPs
   ```

3. **Typo in filename**
   ```bash
   # You typed: hosts_refrence.yml (missing 'e')
   # File actually: hosts_reference.yml (with 'e')
   
   # Compare carefully to avoid typos
   ```

**DEBUGGING STEPS:**

```bash
# Step 1: Where am I?
pwd
# Should output: .../lab-exercises/Task1

# Step 2: What files exist?
ls -la inventory/
# Should show: hosts_reference.yml, hosts_template.yml, group_vars/

# Step 3: Full path debugging
ansible-playbook -i $(pwd)/inventory/hosts_reference.yml playbooks/solution/ce01_solution.yml
# Using full path removes directory confusion
```

**FIX PRIORITY:**
1. `cd lab-exercises/Task1`
2. `ls -la inventory/` - verify files exist
3. Use full paths in commands: `$(pwd)/inventory/...`

---

### Issue 3: "ERROR: YAML syntax error"

**WHAT this error means:**
```
ERROR! mapping values are not allowed here (line 5, column 10)
```

**WHY this happens:**
YAML is very strict about spacing:
- Wrong indentation = syntax error
- Forgotten colons = syntax error
- Tabs instead of spaces = syntax error

**ROOT CAUSES:**

1. **Wrong indentation in YAML file**
   ```yaml
   # WRONG (1 space):
    red_vlan:
    id: 10
   
   # RIGHT (2 spaces):
   red_vlan:
     id: 10
   ```

2. **Spaces vs tabs**
   ```bash
   # YAML expects spaces, not tabs
   # This file uses tabs (WRONG):
   cat -A inventory/group_vars/nxos.yml | head -5
   # If you see: ^I (that's a tab)
   
   # FIX: Replace tabs with spaces
   sed -i 's/\t/  /g' inventory/group_vars/nxos.yml
   ```

3. **Missing colon after key**
   ```yaml
   # WRONG:
   red_vlan
     id: 10
   
   # RIGHT:
   red_vlan:
     id: 10
   ```

**DEBUGGING STEPS:**

```bash
# Step 1: Syntax check the file
python3 -c "import yaml; yaml.safe_load(open('inventory/group_vars/nxos.yml'))"
# If error: shows line number with problem

# Step 2: Show line numbers in editor
# Most editors: Ctrl+G to go to line number in error

# Step 3: Compare to template
diff inventory/group_vars_nxos_template.yml inventory/group_vars/nxos.yml
# Shows exactly what's different
```

**FIX PRIORITY:**
1. Run syntax check to find exact line
2. Go to that line in editor
3. Compare indentation with solution file
4. Fix spacing (must be 2-space indentation)

---

### Issue 4: "FAILED: MODULE EXECUTION ERROR - state must be one of: merged, replaced, overridden..."

**WHAT this error means:**
```
fatal: [n9k-ce01]: FAILED! => {
    "msg": "value of state must be one of: merged, replaced, overridden, deleted, rendered, gathered, parsed, got: present"
}
```

**WHY this happens:**
Different Cisco modules use different `state` values:
- IOS modules: `state: present / absent`
- NXOS modules: `state: merged / replaced / deleted`

Using WRONG state value = module rejects it

**ROOT CAUSE:**
```yaml
# WRONG for NXOS (this is IOS syntax):
- cisco.nxos.nxos_vlans:
    state: present      # ← NXOS doesn't understand "present"
    config: ...

# RIGHT for NXOS:
- cisco.nxos.nxos_vlans:
    state: merged       # ← NXOS understands "merged" (create/update)
    config: ...
```

**Difference explained:**
- `present` = "exists or not" (binary thinking)
- `merged` = "combine with existing configuration" (more powerful)

For beginning tasks, use `merged`:
- Creates VLAN if doesn't exist
- Updates VLAN if exists with different name
- Safe to run multiple times

**DEBUGGING STEPS:**

```bash
# Step 1: Find which task failed
# Error message shows: "TASK [... Create VLAN ...]"
# That's your problem task

# Step 2: Check state value
grep "state:" playbooks/solution/ce01_solution.yml | head -1
# Should show: state: merged

# Step 3: Compare to solution
diff playbooks/student/ce01_student_template.yml playbooks/solution/ce01_solution.yml
# Look for state: lines
```

**FIX PRIORITY:**
1. Find the exact line with error (shown in error message)
2. Change `state: present` to `state: merged`
3. Re-run playbook

---

### Issue 5: "Clients still can't ping each other after configuration"

**WHAT this error means:**
```
docker exec clab-LTRATO-1001-linux-client1 ping -c 2 23.23.23.2
# Result: 100% packet loss
# ← Packets are being lost, not reaching destination
```

**WHY this happens:**
Multiple possible causes - need to debug systematically:

**Debugging flow:**

**Step 1: Verify playbook ran successfully**
```bash
# Did Ansible report errors?
# Check last playbook output:
# PLAY RECAP should show: changed=X, failed=0

# If failed > 0: Fix Ansible errors first, then test
# If failed = 0: Move to step 2
```

**Step 2: Verify VLAN exists on switch**
```bash
# SSH to the switch
ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30

# Check VLAN exists
n9k-ce01# show vlan id 10
# EXPECTED:
# VLAN 10   RED_CLIENTS                   active    Eth1/3, Eth1/4

# If VLAN not found: Ansible didn't create it (re-run playbook)
# If ports missing: Ansible didn't configure them (re-run playbook)
```

**Step 3: Verify ports are configured correctly**
```bash
# Still SSH'd in as above

# Check Ethernet1/3
n9k-ce01# show interface Ethernet1/3
# EXPECTED OUTPUT:
# Ethernet1/3 is up, line protocol is up
# Port mode is access
# Access VLAN: 10

# If "Port mode is trunk": Wrong config type
# If "Access VLAN: --": Not assigned to VLAN (re-run playbook)
# If "Ethernet1/3 is down": Port isn't enabled (re-run playbook)
```

**Step 4: Verify client containers are connected**
```bash
# Docker container connects to switch via simulated network interface
# This can fail if container isn't running

# Check if containers exist
docker ps | grep -E "client1|client2|client3|client4"
# Should show all 4 running

# If one is missing: Lab setup issue, contact admin
```

**Step 5: Check ARP learning (MAC address resolution)**
```bash
# Inside switch:
n9k-ce01# show arp vlan 10
# EXPECTED:
# 23.23.23.1    <mac-address1>    dynamic    Eth1/3
# 23.23.23.2    <mac-address2>    dynamic    Eth1/4

# If MAC addresses are missing:
# First ping from client1 hasn't happened yet
# Try: docker exec clab-LTRATO-1001-linux-client2 ping -c 1 23.23.23.1
# (ping from client2 first to populate ARP in reverse direction)
# Then try: docker exec clab-LTRATO-1001-linux-client1 ping -c 2 23.23.23.2
# (now client1→client2 should work)
```

**DEBUGGING PRIORITY:**
1. Verify Ansible playbook ran without errors (failed=0)
2. SSH to switch and run `show vlan id 10`
3. Verify ports show correct VLAN and "is up"
4. Check if clients are running: `docker ps | grep client`
5. Try bidirectional pings to populate ARP
6. If still issues, check ARP table

---

### Issue 6: "Playbook shows 'ok' but I can't verify configuration"

**WHAT this error means:**
```
PLAY RECAP ****
n9k-ce01 : ok=4 changed=0 unreachable=0 failed=0

# But when you SSH to switch: VLAN doesn't exist!
```

**WHY this happens:**
- Playbook ran on DIFFERENT device than you expected
- Or playbook targeted the REFERENCE inventory but you modified template
- Configuration applied but not to the device/port you were testing

**ROOT CAUSES:**

1. **Playbook targets wrong device**
   ```yaml
   # In playbook file:
   - hosts: nxos     # What group of devices?
   # Looks up inventory and finds ALL devices in "nxos" group
   # Runs on all of them!
   # If you specified: hosts: ce01_only
   # But inventory has everyone in "nxos": will run on both
   ```

2. **You tested wrong switch**
   ```bash
   # You ran playbook against reference inventory (n9k-ce01)
   # But SSHed to n9k-ce02 to check
   # FIX: Check which inventory was used (printed at top of playbook run)
   ```

3. **VLAN created but you're looking at wrong VLAN**
   ```bash
   # Playbook creates VLAN 10
   # You run: show vlan id 20
   # of course it doesn't exist! (looking at wrong VLAN)
   ```

**DEBUGGING STEPS:**

```bash
# Step 1: Re-run playbook with -v flag (verbose)
ansible-playbook ...-v
# Top of output shows what device is being targeted

# Step 2: Verify correct device
# Output bottom shows: "PLAY RECAP n9k-ce01 : ..."
# Means changes were on n9k-ce01

# Step 3: SSH to THAT device
ssh -i ~/.ssh/id_ed25519 admin@172.20.20.30

# Step 4: Check CORRECT VLAN
n9k-ce01# show vlan id 10
# Not id 20!
```

---

### Issue 7: "Playbook shows 'changed=0' (no changes made)"

**WHAT this means:**
```
PLAY RECAP ****
n9k-ce01 : ok=4 changed=0 unreachable=0 failed=0
# ↑ changed=0 = no changes were made
```

**IS THIS A PROBLEM?** NO! ✅

**WHY changed=0 is actually GOOD:**

- First run: changed=4 (VLAN didn't exist, created it)
- Second run: changed=0 (VLAN already exists, nothing to change)
- This is **idempotency** - the correct behavior!

**WHEN changed=0 IS BAD:**
Only if you ran the playbook the FIRST time and got changed=0

```bash
# This sequence is wrong:
First run: changed=0  ← BAD! Should have created VLAN
           failed=0

# Means: Playbook ran but made no changes
# Why? Check:
# 1. Is VLAN already there? (maybe pre-configured)
# 2. Did playbook actually execute? (check it ran)
# 3. Check device config manually

# FIX: SSH to device and verify manually
ssh ... admin@172.20.20.30
n9k-ce01# show vlan id 10
# If it exists: playbook worked! changed=0 is normal second time
# If it doesn't exist: playbook ran on wrong device
```

**LEARNING POINT:**
```
FIRST RUN:  changed=4 or changed=3 or changed=1 (varies)
SECOND RUN: changed=0 (always - configuration already there)
TENTH RUN:  changed=0 (still - Ansible is maintaining statefulness)

This is exactly what we want!
```

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
