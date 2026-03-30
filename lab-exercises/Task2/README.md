# Task 2: ISIS Configuration via Ansible

**Time:** ~1 hour  
**Devices:** CSR-PE01, CSR-PE02, N9K-CE01, N9K-CE02  
**Goal:** Deploy ISIS routing between CSRs and N9Ks so clients can reach PE loopbacks

---

## 📋 5-Step Learning Track

### **Step 1: Review Inventory** (5 min)
Understand which devices you're configuring.

```bash
cd lab-exercises/Task2
cat inventory/hosts.yml | grep -A 20 "^all:"
```

**Look for:** CSR and N9K device groups with their IP addresses.

---

### **Step 2: Examine Variables** (10 min)
Check the per-device configuration parameters.

```bash
# View CSR variables
cat group_vars/csr/csr-pe01.yml
cat group_vars/csr/csr-pe02.yml

# View N9K variables
cat group_vars/nxos/n9k-ce01.yml
cat group_vars/nxos/n9k-ce02.yml
```

**What to look for:**
- `isis_router_name` — e.g., `CORE`, `CUSTOMER_RED`
- `isis_net_address` — ISIS network addresses for each device/area
- `isis_level` — `level-1-only` (CE) or `level-2-only` (PE)

---

### **Step 3: Study Playbooks** (20 min)
Understand how Ansible configures each device type.

```bash
# CSR playbook (configures PE devices)
cat playbooks/01_deploy_isis_csr.yml

# N9K playbook (configures CE devices)
cat playbooks/02_deploy_isis_nxos.yml

# Validation playbook
cat playbooks/03_validate_isis.yml
```

**Key Ansible Concepts:**
- `ios_config` module — sends commands to CSRs
- `nxos_config` module — sends commands to N9Ks
- `when:` conditions — runs tasks only on specific devices
- Variables — templated into configuration commands

---

### **Step 4: Run Playbooks** (15 min)
Deploy the configuration.

```bash
# Deploy to CSRs
ansible-playbook -i inventory/hosts.yml playbooks/01_deploy_isis_csr.yml

# Deploy to N9Ks
ansible-playbook -i inventory/hosts.yml playbooks/02_deploy_isis_nxos.yml

# Watch for "ok" or "changed" status — no "failed"
```

---

### **Step 5: Validate Configuration** (10 min)
Confirm ISIS is working.

```bash
# Run validation playbook
ansible-playbook -i inventory/hosts.yml playbooks/03_validate_isis.yml

# Manually verify on devices:
# SSH to CSR and check:
ssh admin@clab-LTRATO-1001-csr-pe01
  show isis neighbors
  show ip route isis

# SSH to N9K and check:
ssh admin@clab-LTRATO-1001-n9k-ce01
  show isis neighbors
  show ip route isis

# Test client connectivity:
ssh root@clab-LTRATO-1001-linux-client1
  ping 192.168.10.11
  ping 192.168.10.12
```

**Expected Results:**
- ✅ ISIS neighbors appear in `show isis neighbors`
- ✅ Loopback routes learned via ISIS (`show ip route isis`)
- ✅ Clients can ping PE loopbacks

---

## 📂 File Structure

```
Task2/
├── README.md                          ← This file
├── inventory/
│   ├── hosts.yml                      ← Device list (shared with Task 1)
│   └── group_vars/
│       ├── csr/
│       │   ├── csr-pe01.yml           ← [FILL IN] PE01 ISIS config
│       │   └── csr-pe02.yml           ← [FILL IN] PE02 ISIS config
│       └── nxos/
│           ├── n9k-ce01.yml           ← [FILL IN] CE01 ISIS config
│           └── n9k-ce02.yml           ← [FILL IN] CE02 ISIS config
└── playbooks/
    ├── 01_deploy_isis_csr.yml         ← Deploy to CSRs
    ├── 02_deploy_isis_nxos.yml        ← Deploy to N9Ks
    └── 03_validate_isis.yml           ← Verify configuration
```

---

## 🔄 Connection to Other Tasks

**Builds on:** Task 1 (VLAN connectivity, client IPs)  
**Foundation for:** Task 3 (BGP routing between XRd and CSR)

---

## 💡 Ansible Concepts You'll See

| Concept | Where | Purpose |
|---------|-------|---------|
| **Inventory groups** | `hosts.yml` | Organize devices by type (csr, nxos, clients) |
| **Group variables** | `group_vars/csr/` | Define per-device ISIS configuration |
| **Conditional tasks** | `when: inventory_hostname == 'csr-pe01'` | Run config on specific devices |
| **Modules** | `ios_config`, `nxos_config` | Send commands to network devices |
| **Jinja2 templates** | Inside playbooks | Dynamically generate commands from variables |

---

## ❓ Troubleshooting

**Playbook fails:**  
→ Check `ansible-playbook` output for error messages  
→ Verify SSH works: `ssh admin@device-ip "show version"`

**ISIS neighbors don't appear:**  
→ Verify interfaces are up: `show int status`  
→ Check ISIS is enabled: `show isis process`

**Clients can't ping PE:**  
→ Check routes exist: `show ip route isis`  
→ Verify firewall/ACLs not blocking ICMP
