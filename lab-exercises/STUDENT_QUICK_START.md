# Student Quick Start Guide

**You don't need to understand SSH configuration or networking internals. This guide assumes your instructor has already verified everything is working. Just follow these steps.**

---

## Before You Start

✅ Your instructor has verified all devices are reachable  
✅ Ansible is configured correctly  
✅ You can focus on learning Ansible network automation  

---

## How to Run the Lab Exercises

### Task 1: Deploy VLANs (15 minutes)

```bash
cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises

ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml
```

**What to expect:**
- Output shows `ok=6` (6 tasks completed)
- Look for `VLAN 10` and `VLAN 20` created on N9K devices
- All tasks should be green (no red errors)

**Verify it worked:**
- Read the debug output showing VLAN status
- VLANs 10 and 20 should be present

---

### Task 2a: Deploy ISIS on CSR (10 minutes)

```bash
ansible-playbook -i inventory/hosts.yml Task2/playbooks/01_deploy_isis_csr.yml
```

**What to expect:**
- Output shows `ok=7` (7 tasks completed)
- ISIS routers configured on both CSR devices (CORE and CUSTOMER instances)
- All tasks should be green

**Verify it worked:**
- Both CSR devices have ISIS neighbors
- `show isis neighbors` confirms adjacencies

---

### Task 2b: Deploy ISIS on N9K (10 minutes)

```bash
ansible-playbook -i inventory/hosts.yml Task2/playbooks/02_deploy_isis_nxos.yml
```

**What to expect:**
- Output shows `ok=5` (5 tasks completed)
- ISIS configured on N9K devices
- Configuration saved to startup-config
- All tasks should be green

**Verify it worked:**
- N9K devices have ISIS neighbors
- Loopback0 and Eth2/1, Eth2/2 are configured

---

## If Something Goes Wrong

### Error: "No module named ansible"
**Solution:** Ansible is not installed. Ask your instructor.

### Error: "Permission denied"
**Solution:** You don't have credentials. Ask your instructor.

### Error: "Connection refused"
**Solution:** Device is unreachable. Ask your instructor to run INSTRUCTOR_SETUP.sh.

### Otherwise
**Solution:** Ask your instructor. They can check logs with:
```bash
ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml -vvv
```

---

## What You're Learning

✅ How Ansible automates network configuration  
✅ How to structure playbooks for multi-device deployment  
✅ How to validate configuration with Ansible  
✅ VLAN configuration (Task 1)  
✅ ISIS routing setup (Task 2)  

---

## That's It!

Run the three playbooks above, verify they work, and you're done. 

**Total time: ~35-40 minutes**

Your instructor handles all the infrastructure complexity. You focus on learning Ansible.
