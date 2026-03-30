# Lab Exercises - Student Guide

Welcome to the Cisco Live 2026 Service-as-Code lab! 

This guide will get you up and running with Ansible network automation in under an hour.

---

## 📋 Three Simple Tasks

### **Task 1: Deploy VLANs (15 minutes)**

Run this command:
```bash
cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises
ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml
```

**What happens:**
- VLANs 10 and 20 are deployed to network switches
- You'll see green checkmarks for each task
- Ansible validates the VLANs are configured correctly

**To learn more:** See [Task1/README.md](Task1/README.md)

---

### **Task 2a: Deploy ISIS on CSR Routers (10 minutes)**

Run this command:
```bash
ansible-playbook -i inventory/hosts.yml Task2/playbooks/01_deploy_isis_csr.yml
```

**What happens:**
- ISIS routing is configured on CSR routers
- Two ISIS instances are created (CORE and CUSTOMER)
- Ansible verifies the configuration is active

**To learn more:** See [Task2/README.md](Task2/README.md)

---

### **Task 2b: Deploy ISIS on N9K Switches (10 minutes)**

Run this command:
```bash
ansible-playbook -i inventory/hosts.yml Task2/playbooks/02_deploy_isis_nxos.yml
```

**What happens:**
- ISIS routing is configured on Nexus switches
- Loopback and interface configurations are applied
- Configuration is saved to persistent storage

**To learn more:** See [Task2/README.md](Task2/README.md)

---

## 🎓 What You'll Learn

✅ How to use Ansible for network automation  
✅ How to structure playbooks for multiple devices  
✅ How to configure VLAN and routing protocols  
✅ How to validate device configuration with Ansible  

---

## ⚠️ If Something Fails

If any playbook shows red errors:

1. **Read the error message** — It usually tells you exactly what's wrong
2. **Check the device is reachable** — Ask your instructor to verify connectivity
3. **Ask your instructor** — They have all the troubleshooting tools

**Do NOT try to fix SSH, connectivity, or infrastructure issues yourself** — your instructor handles all that.

---

## ✅ Success Indicators

Each playbook should show output like:

```
TASK [...]
ok: [device1]
ok: [device2]

PLAY RECAP
device1 : ok=X  changed=X  unreachable=0  failed=0
device2 : ok=X  changed=X  unreachable=0  failed=0
```

✅ **All tasks are green** → Success  
🔴 **Any red "FAILED"** → Ask instructor  

---

## 📚 Deep Dives (Optional)

Want to understand the playbooks better?

- **Task 1 Deep Dive** → [Task1/README.md](Task1/README.md)
- **Task 2 Deep Dive** → [Task2/README.md](Task2/README.md)

These explain:
- Playbook structure
- Variable usage
- Device configurations
- Validation methods

---

## ⏱️ Timeline

| Task | Time | Command |
|------|------|---------|
| Task 1: VLAN | 15 min | `ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml` |
| Task 2a: ISIS CSR | 10 min | `ansible-playbook -i inventory/hosts.yml Task2/playbooks/01_deploy_isis_csr.yml` |
| Task 2b: ISIS N9K | 10 min | `ansible-playbook -i inventory/hosts.yml Task2/playbooks/02_deploy_isis_nxos.yml` |
| **Total** | **~40 min** | |

---

**Ready? Start with Task 1!**

```bash
cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises
ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml
```
