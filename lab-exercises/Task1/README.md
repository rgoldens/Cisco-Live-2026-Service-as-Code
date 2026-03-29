# TASK 1: Reachability Service - Red & Purple Client Configuration

## Quick Start

**Objective:** Enable Layer 2 connectivity between RED clients and between PURPLE clients using Ansible

**Time:** 45 minutes  
**Difficulty:** Beginner  

## Files in This Directory

```
Task1/
├── Task1-Ansible.md               ← START HERE (complete guide)
├── README.md                       ← This file
├── inventory/
│   ├── hosts_template.yml          ← Students fill in IPs here
│   ├── hosts_reference.yml         ← Solution
│   ├── group_vars_nxos_template.yml  ← Students fill in variables
│   └── group_vars_nxos_reference.yml ← Solution
└── playbooks/
    ├── student/
    │   ├── ce01_student_template.yml  ← Students complete this
    │   └── ce02_student_template.yml  ← Students complete this
    ├── solution/
    │   ├── ce01_solution.yml          ← Reference solution
    │   └── ce02_solution.yml          ← Reference solution
    └── helper/
        └── validate_task1.yml         ← Validation playbook
```

## Lab Topology

```
RED CLIENTS                      ORANGE                      GREEN              BLUE
client1 (23.23.23.1)    ─eth1←→Eth1/3─┐
                                  ├─→ n9k-ce01 ──Eth1/1──→ csr-pe01
client2 (23.23.23.2)    ─eth1←→Eth1/4─┘                  (to xrd01)

client3 (34.34.34.1)    ─eth1←→Eth1/3─┐
                                  ├─→ n9k-ce02 ──Eth1/1──→ csr-pe02
client4 (34.34.34.2)    ─eth1←→Eth1/4─┘                  (to xrd02)
```

## Steps to Complete Task 1

### 1. Fill in Inventory (10 min)
```bash
# Edit inventory/hosts_template.yml
# Replace management IPs for n9k-ce01 and n9k-ce02
```

### 2. Create Variables (5 min)
```bash
# Create inventory/group_vars/nxos.yml 
# Copy from inventory/group_vars_nxos_template.yml
# Verify VLAN IDs: 10 for RED, 20 for PURPLE
```

### 3. Complete Student Playbooks (10 min)
```bash
# Edit playbooks/student/ce01_student_template.yml
# Edit playbooks/student/ce02_student_template.yml
# Answer all TODOs by comparing to solutions
```

### 4. Run Playbooks (10 min)
```bash
ansible-playbook -i inventory/hosts_reference.yml \
  playbooks/solution/ce01_solution.yml \
  -e @inventory/group_vars/nxos.yml

ansible-playbook -i inventory/hosts_reference.yml \
  playbooks/solution/ce02_solution.yml \
  -e @inventory/group_vars/nxos.yml
```

### 5. Validate (5 min)
```bash
# Test RED clients ping
docker exec clab-LTRATO-1001-linux-client1 ping -c 2 23.23.23.2

# Test PURPLE clients ping
docker exec clab-LTRATO-1001-linux-client3 ping -c 2 34.34.34.2

# Both should show: "2 packets transmitted, 2 received"
```

## Success Criteria

✅ RED clients (client1 & client2) can ping each other  
✅ PURPLE clients (client3 & client4) can ping each other  
✅ VLAN 10 exists on n9k-ce01 with Eth1/3 and Eth1/4  
✅ VLAN 20 exists on n9k-ce02 with Eth1/3 and Eth1/4  

## Key Commands

```bash
# Test inventory
ansible all -i inventory/hosts_reference.yml --list-hosts

# Ping devices
ansible all -i inventory/hosts_reference.yml -m ping

# Run playbook in verbose mode
ansible-playbook -i inventory/hosts_reference.yml playbooks/solution/ce01_solution.yml -v

# Check VLAN on switch
ssh admin@172.20.20.30
n9k-ce01# show vlan id 10
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Permission denied` | Check SSH key path: `~/.ssh/id_ed25519` |
| `Unreachable` | Verify inventory IPs are correct (172.20.20.30, 172.20.20.31) |
| `Clients can't ping` | Run validation playbook to check VLAN config |
| `Nothing changes on rerun` | This is normal! Ansible is idempotent |

## What You'll Learn

- What is Ansible and how to write playbooks
- How to build an inventory file
- How to use variables in Ansible
- Layer 2 switching concepts (VLANs, access ports)
- How to validate network configuration
- Infrastructure as Code principles

## Next Steps

After Task 1 succeeds:
→ Proceed to **Task 2: Loopback Provisioning**

## Resources

- Full guide: `Task1-Ansible.md`
- Ansible docs: https://docs.ansible.com/ansible/latest/
- Cisco NXOS modules: https://docs.ansible.com/ansible/latest/collections/cisco/nxos/

---

**Ready?** Start with `Task1-Ansible.md` 🚀
