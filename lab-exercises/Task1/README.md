# Task 1: VLAN Configuration via Ansible

**Goal:** Learn Ansible fundamentals by automating VLAN configuration on two N9K switches.

**Time:** ~1 hour  
**Focus:** Ansible skills (inventory, variables, playbooks, modules)

---

## What You're Building

Configure two Nexus switches to create isolated network segments:

| Segment | VLAN | Clients | Purpose |
|---------|------|---------|---------|
| **RED** | 10 | client1, client2 | Can reach each other (same VLAN) |
| **PURPLE** | 20 | client3, client4 | Can reach each other (same VLAN) |

**Why:** Demonstrates how Ansible automates network configuration instead of manual CLI commands.

---

## 5-Step Track (1 hour)

| Step | Task | Time | What You'll Do |
|------|------|------|---|
| **1** | Review Inventory | 5 min | Read `../inventory/hosts.yml` — understand device groups |
| **2** | Fill Variables | 10 min | Edit `group_vars/nxos.yml` — add VLAN IDs and port assignments |
| **3** | Study Playbook | 15 min | Review `playbooks/01_task1_vlans.yml` — understand how Ansible loops/templates work |
| **4** | Run Playbook | 10 min | Execute playbook → deploys VLAN config to both switches |
| **5** | Validate | 10 min | Run ping tests from client containers → verify connectivity |
| **+** | Buffer | 10 min | Time for questions/troubleshooting |

---

## File Structure

```
Task1/
├── README.md (this file)
├── PLAYBOOK_WALKTHROUGH.md (detailed playbook explanation)
├── group_vars/
│   └── nxos.yml (← YOU FILL THIS IN)
└── playbooks/
    └── 01_task1_vlans.yml (pre-written, well-commented)
```

---

## Step 1: Review Inventory (5 min) ✅

**File:** `../inventory/hosts.yml`

```bash
cat ../inventory/hosts.yml | grep -A 10 "nxos:"
```

You'll see:
```yaml
nxos:
  hosts:
    n9k-ce01:
      ansible_host: 172.20.20.30
    n9k-ce02:
      ansible_host: 172.20.20.31
  vars:
    ansible_user: admin
    ansible_password: admin
```

**What this means:**
- Both N9K switches are in the `nxos` **group**
- Shared credentials (admin/admin) for the group
- Individual host entries with management IPs
- Playbooks targeting `hosts: nxos` will run on both switches

---

## Step 2: Fill Variables (10 min) 📝

**File:** `group_vars/nxos.yml`

Template structure:
```yaml
vlans:
  - vlan_id: <RED_ID>
    name: RED_CLIENTS
    interfaces:
      - Ethernet1/3
      - Ethernet1/4
  
  - vlan_id: <PURPLE_ID>
    name: PURPLE_CLIENTS
    interfaces:
      - Ethernet1/3
      - Ethernet1/4
```

**Your job:**
1. Replace `<RED_ID>` with `10`
2. Replace `<PURPLE_ID>` with `20`
3. Save file

**Concept:** Variables are shared by all devices in the `nxos` group. The playbook will apply this to both n9k-ce01 and n9k-ce02.

---

## Step 3: Study Playbook (15 min) 📖

**File:** `playbooks/01_task1_vlans.yml`

Key sections:

### Section 1: Create VLANs
```yaml
- name: Create VLANs
  cisco.nxos.nxos_vlans:
    vlan_id: "{{ item.vlan_id }}"
    name: "{{ item.name }}"
    state: present
  loop: "{{ vlans }}"
```

**What it does:**
- `loop: "{{ vlans }}"` — repeat for each VLAN in your variables
- `{{ item.vlan_id }}` — Jinja2 template extracts ID from current loop item
- `state: present` — create VLAN if it doesn't exist (idempotent)

**In plain English:** "For each VLAN in my variables, create it on this device"

### Section 2: Configure Access Ports
```yaml
- name: Configure access ports
  cisco.nxos.nxos_l2_interfaces:
    name: "{{ item.interface }}"
    mode: access
    access:
      vlan: "{{ item.vlan_id }}"
  loop: "{{ vlans | selectattr('interfaces') }}"
```

**What it does:**
- Iterates through interfaces from each VLAN
- Sets mode to `access` (instead of trunk)
- Assigns the interface to the correct VLAN

**In plain English:** "Put each interface in access mode and assign it to its VLAN"

---

## Step 4: Run Playbook (10 min) ▶️

```bash
cd ~/lab-exercises/Task1

ansible-playbook -i ../inventory/hosts.yml playbooks/01_task1_vlans.yml -v
```

**What you'll see:**
```
TASK [Create VLANs] ****
changed: [n9k-ce01] => (item={'vlan_id': 10, ...})
changed: [n9k-ce01] => (item={'vlan_id': 20, ...})
changed: [n9k-ce02] => (item={'vlan_id': 10, ...})
changed: [n9k-ce02] => (item={'vlan_id': 20, ...})

TASK [Configure access ports] ****
changed: [n9k-ce01] ...
changed: [n9k-ce02] ...

PLAY RECAP ***
n9k-ce01: ok=2 changed=2 unreachable=0 failed=0
n9k-ce02: ok=2 changed=2 unreachable=0 failed=0
```

**Interpretation:**
- `changed=2` = 2 tasks modified device config
- `ok=2` = all tasks succeeded
- If you see `failed=1`, check your variables file for typos

---

## Step 5: Validate (10 min) ✅

Test RED clients (should reach each other):
```bash
ansible linux-client1 -i ../inventory/hosts.yml -m raw -a "ping -c 3 172.20.20.41"
```

Expected output: `3 received, 0% loss`

Test PURPLE clients (should reach each other):
```bash
ansible linux-client3 -i ../inventory/hosts.yml -m raw -a "ping -c 3 172.20.20.43"
```

Expected output: `3 received, 0% loss`

**If pings fail:**
1. Verify playbook succeeded (check output above)
2. Check variables file for typos
3. SSH to switch: `ssh admin@172.20.20.30` then `show vlan` to debug

---

## Ansible Concepts You've Just Used

| Concept | You used it for | Where |
|---------|-----------------|-------|
| **Inventory** | Define which devices exist | `../inventory/hosts.yml` |
| **Groups** | Organize devices (nxos, clients) | `nxos:` section |
| **Variables** | Share data across devices | `group_vars/nxos.yml` |
| **Jinja2 templates** | Substitute values dynamically | `{{ item.vlan_id }}` |
| **Loops** | Repeat tasks | `loop: "{{ vlans }}"` |
| **Modules** | Perform specific actions | `nxos_vlans`, `nxos_l2_interfaces` |
| **Idempotency** | Safe re-runs | `state: present` |
| **Hosts targeting** | Run on specific devices | `hosts: nxos` in playbook |

---

## Task 1 Complete ✅

When all 3 success criteria pass:
- ✅ Playbook showed `changed=X` with no failures
- ✅ RED clients ping test = 0% loss
- ✅ PURPLE clients ping test = 0% loss

**Next:** Proceed to `Task 2/` for ISIS routing configuration!
